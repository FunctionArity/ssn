class GuardsController < ApplicationController
  before_action :set_guard, only: %i[ show edit update destroy close history ]
  before_action :set_services_count, only: %i[ show ]

  def index
    service = CreateGuardFromSetupService.new
    @new_guard = service.call if service.guard_setup?
    @guards = Guard.includes(:vocal, :priest, :guardians).order("due_date DESC")
    @services_count_by_guard = Service.group(:guard_id).count

    unless @guards.any? { |g| g.due_date == Date.current }
      @today_guard_setup = GuardSetup.includes(:vocal, :guardians).find_by(day_number: Date.current.day)
    end
  end

  def show
  end

  def history
    authorize @guard
    @versions = @guard.versions.reorder(created_at: :desc, id: :desc)
    @authors = User.where(id: @versions.filter_map(&:whodunnit).uniq).index_by { |user| user.id.to_s }
  end

  def close
    authorize @guard
    @guard.closed!
    redirect_to @guard, notice: t("guards.notices.closed")
  end

  def new
    service = CreateGuardFromSetupService.new(params[:guard_setup_id])
    return redirect_to guards_path, alert: t("guards.errors.no_guard_setup") unless service.guard_setup?
    @guard = service.call
    authorize @guard
  end

  def edit
    authorize @guard
  end

  def create
    @guard = Guard.new(guard_params)
    authorize @guard

    respond_to do |format|
      if @guard.save
        format.html { redirect_to @guard, notice: t("guards.notices.created") }
        format.json { render :show, status: :created, location: @guard }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @guard.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @guard
    respond_to do |format|
      if @guard.update(guard_params)
        format.html { redirect_to @guard, notice: t("guards.notices.updated"), status: :see_other }
        format.json { render :show, status: :ok, location: @guard }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @guard.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @guard
    @guard.destroy!

    respond_to do |format|
      format.html { redirect_to guards_path, notice: t("guards.notices.destroyed"), status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_guard
    @guard = Guard.find(params.expect(:id))
  end

  def set_services_count
    @services = @guard.services.includes(:health_facility).order(:position)
    @services_count = @services.size
  end

  def guard_params
    params.expect(guard: [ :day_number, :due_date, :notes, :status, :vocal_id, :priest_id, :guard_setup_id, guardian_ids: [] ])
  end
end
