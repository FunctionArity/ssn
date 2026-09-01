class GuardsController < ApplicationController
  before_action :set_guard, only: %i[ show edit update destroy close pdf preview confirm_pdf ]
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

  def close
    authorize @guard
    @guard.closed!
    redirect_to @guard, notice: t("guards.notices.closed")
  end

  def pdf
    if @guard.pdf_file.attached?
      redirect_to rails_blob_url(@guard.pdf_file, disposition: "inline")
    else
      pdf_data = GuardPdf.new(@guard).render
      send_data pdf_data,
        filename: "guardia_#{@guard.id}.pdf",
        type: "application/pdf",
        disposition: "inline"
    end
  end

  def preview
    if params[:first_nro].present?
      @first_nro = params[:first_nro].to_i
    else
      last_nro = Service.where.not(nro: nil).maximum(:nro)
      @first_nro = last_nro ? last_nro + 1 : 1
    end
    @services = @guard.services.completed.includes(:health_facility).order(due_date: :asc)
    @services.each_with_index { |s, i| s.nro = @first_nro + i }
  end

  def confirm_pdf
    first_nro = params[:first_nro].to_i
    @guard.services.completed.order(due_date: :asc).each_with_index do |service, idx|
      service.update_column(:nro, first_nro + idx)
    end
    pdf_data = GuardPdf.new(@guard.reload).render
    @guard.pdf_file.attach(
      io: StringIO.new(pdf_data),
      filename: "guardia_#{@guard.id}.pdf",
      content_type: "application/pdf"
    )
    @guard.closed!
    redirect_to pdf_guard_path(@guard)
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
