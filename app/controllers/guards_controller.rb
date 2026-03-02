class GuardsController < ApplicationController
  before_action :set_guard, only: %i[ show edit update destroy ]

  def index
    @guards = Guard.includes(:vocal, :priest, :guardians).order(:day_number)
  end

  def show
  end

  def new
    @guard = CreateGuardFromSetupService.new(params[:guard_setup_id]).call
  end

  def edit
  end

  def create
    @guard = Guard.new(guard_params)

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

  def guard_params
    params.expect(guard: [ :day_number, :due_date, :notes, :vocal_id, :priest_id, :guard_setup_id, guardian_ids: [] ])
  end
end
