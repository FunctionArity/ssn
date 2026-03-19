class GuardsController < ApplicationController
  before_action :set_guard, only: %i[ show edit update destroy close pdf ]
  before_action :set_services_count, only: %i[ show ]

  def index
    @guards = Guard.includes(:vocal, :priest, :guardians).order("due_date DESC")
    @services_count_by_guard = Service.group(:guard_id).count
  end

  def show
  end

  def close
    @guard.closed!
    redirect_to @guard, notice: t("guards.notices.closed")
  end

  def pdf
    pdf_data = GuardPdf.new(@guard).render
    send_data pdf_data,
      filename: "guardia_#{@guard.id}.pdf",
      type: "application/pdf",
      disposition: "inline"
  end

  def new
    due_date = params[:due_date].present? ? Date.parse(params[:due_date]) : Date.current
    @guard = CreateGuardFromSetupService.new(params[:guard_setup_id], due_date).call
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
    @services = @guard.services.includes(:health_facility).order(due_date: :desc)
    @services_count = @services.size
  end

  def guard_params
    params.expect(guard: [ :day_number, :due_date, :notes, :status, :vocal_id, :priest_id, :guard_setup_id, guardian_ids: [] ])
  end
end
