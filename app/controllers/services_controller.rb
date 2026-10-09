class ServicesController < ApplicationController
  before_action :set_service, only: %i[ show edit update destroy pdf complete move ]

  def index
    @current_guard = Guard.includes(:vocal, :priest, :guardians).find_by(status: :open, due_date: Date.current)
    @services = @current_guard ? @current_guard.services.includes(:created_by).order(:position) : Service.none
    @pending_other_services = Service.pending
                                     .includes(:guard, :created_by, :health_facility)
                                     .where.not(guard: @current_guard)
                                     .joins(:guard)
                                     .order("guards.due_date DESC", :position)
  end

  def show
  end

  def complete
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

    @service.guard_id = if params[:guard_id].present?
       params[:guard_id]
    else
      GuardService.current&.id
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
        format.html { render :new, status: :unprocessable_entity }
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

  def service_params
    params.expect(service: [ :guard_id, :due_date, :full_name, :age, :status, :caller_full_name, :caller_phone, :caller_relationship, :comments, :address, :health_facility_id, :health_facility_place, :pathology, :health_status, :sacraments ])
  end
end
