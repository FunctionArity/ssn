class ServicesController < ApplicationController
  SEARCH_FILTERS = %i[ full_name health_facility date guard_day caller_phone ].freeze
  RESULTS_PER_PAGE = 12

  before_action :set_service, only: %i[ show edit update destroy pdf complete move history ]

  def index
    @current_guard = Guard.includes(:vocal, :priest, :guardians).find_by(status: :open, due_date: Date.current)
    @filters = params.permit(*SEARCH_FILTERS).to_h.transform_values(&:strip).compact_blank

    if @filters.any?
      set_search_results
      @pending_other_services = Service.none
    else
      @services = @current_guard ? @current_guard.services.includes(:created_by, :health_facility).order(:position) : Service.none
      @pending_other_services = Service.pending
                                       .includes(:guard, :created_by, :health_facility)
                                       .where.not(guard: @current_guard)
                                       .joins(:guard)
                                       .order("guards.due_date DESC", :position)
    end
  end

  def show
  end

  def duplicates
    full_name = params[:full_name].to_s
    @duplicates = full_name.blank? ? Service.none : Service.search_by_full_name(full_name)
                                                           .where(due_date: 2.months.ago.to_date..)
                                                           .includes(:guard, :health_facility)
                                                           .order(due_date: :desc, id: :desc)
  end

  def history
    authorize @service
    @versions = @service.versions.reorder(created_at: :desc, id: :desc)
    @authors = User.where(id: @versions.filter_map(&:whodunnit).uniq).index_by { |user| user.id.to_s }
  end

  def complete
    authorize @service
    @service.completed!
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(@service, partial: "services/small_view", locals: { service: @service }) }
      format.html { redirect_to @service, notice: t("services.notices.completed") }
    end
  end

  def move
    authorize @service, :move?
    @service.insert_at(params.expect(:position).to_i)

    guard = @service.guard
    broadcast_reordered_services(guard)

    respond_to do |format|
      format.turbo_stream {
        if params[:context] == "services_index"
          render turbo_stream: turbo_stream.replace(
            "services",
            partial: "services/services_grid",
            locals: { services: guard.services.includes(:created_by).order(:position) }
          )
        else
          render turbo_stream: turbo_stream.replace(
            "guard_#{guard.id}_services",
            partial: "guards/services_list",
            locals: { guard: guard, services: guard.services.includes(:health_facility).order(:position) }
          )
        end
      }
      format.html { redirect_to guard }
    end
  end

  def pdf
    pdf_data = ServicePdf.new(@service).render
    send_data pdf_data,
      filename: "servicio_#{@service.id}.pdf",
      type: "application/pdf",
      disposition: "inline"
  end

  def new
    @service = Service.new(due_date: Date.current)

    if params[:guard_id].present?
      @service.guard_id = params[:guard_id]
    else
      set_assignable_guards
      @service.guard_id = @assignable_guards.first.id if @assignable_guards.one?
    end

    authorize @service
  end

  def edit
    authorize @service
    set_guards
  end

  def create
    @service = Service.new(service_params)
    @service.created_by = current_user
    authorize @service

    respond_to do |format|
      if @service.save
        format.html { redirect_to @service, notice: t("services.notices.created") }
        format.json { render :show, status: :created, location: @service }
      else
        format.html do
          set_assignable_guards
          render :new, status: :unprocessable_entity
        end
        format.json { render json: @service.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @service
    attributes = policy(@service).change_guard? ? service_params : service_params.except(:guard_id)
    respond_to do |format|
      if @service.update(attributes)
        format.html { redirect_to @service, notice: t("services.notices.updated"), status: :see_other }
        format.json { render :show, status: :ok, location: @service }
      else
        format.html do
          set_guards
          render :edit, status: :unprocessable_entity
        end
        format.json { render json: @service.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @service
    @service.destroy!

    respond_to do |format|
      format.html { redirect_to services_path, notice: t("services.notices.destroyed"), status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_search_results
    results = Service.search(@filters)
    @results_count = results.count
    @total_pages = (@results_count / RESULTS_PER_PAGE.to_f).ceil
    @page = params[:page].to_i.clamp(1, [ @total_pages, 1 ].max)
    @results = results.includes(:guard, :created_by, :health_facility)
                      .order(due_date: :desc, id: :desc)
                      .limit(RESULTS_PER_PAGE)
                      .offset((@page - 1) * RESULTS_PER_PAGE)
  end

  # The guard show list is broadcast by Service's after_update_commit; only the index grid is handled here.
  def broadcast_reordered_services(guard)
    current_guard = Guard.find_by(status: :open, due_date: Date.current)
    return unless current_guard == guard

    @service.broadcast_replace_later_to "services",
      target: "services",
      partial: "services/services_grid",
      locals: { services: guard.services.includes(:created_by).order(:position).to_a }
  end

  def set_service
    @service = Service.find(params.expect(:id))
  end

  # Open guards, plus the service's current guard so it stays selected when that guard is closed.
  def set_guards
    @guards = Guard.where(status: :open).or(Guard.where(id: @service.guard_id_in_database)).order(due_date: :desc)
  end

  # When more than one guard qualifies, the new service form asks which one to use.
  def set_assignable_guards
    @assignable_guards = GuardService.assignable.includes(:priest, :vocal).to_a
  end

  def service_params
    params.expect(service: [ :guard_id, :due_date, :full_name, :age, :status, :caller_full_name, :caller_phone, :caller_relationship, :comments, :address, :health_facility_id, :health_facility_place, :pathology, :health_status, :sacraments ])
  end
end
