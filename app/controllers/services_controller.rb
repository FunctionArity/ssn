class ServicesController < ApplicationController
  before_action :set_service, only: %i[ show edit update destroy pdf complete ]

  def index
    @services = Service.includes(:guard, :created_by).order(due_date: :desc)
    @current_guard = Guard.includes(:vocal, :priest, :guardians).find_by(status: :open, due_date: Date.current)
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
    respond_to do |format|
      if @service.update(service_params)
        format.html { redirect_to @service, notice: t("services.notices.updated"), status: :see_other }
        format.json { render :show, status: :ok, location: @service }
      else
        format.html { render :edit, status: :unprocessable_entity }
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

  def set_service
    @service = Service.find(params.expect(:id))
  end

  def service_params
    params.expect(service: [ :guard_id, :due_date, :full_name, :age, :status, :caller_full_name, :caller_phone, :caller_relationship, :comments, :address, :health_facility_id, :health_facility_place, :pathology, :health_status, :sacraments ])
  end
end
