class GuardSetupsController < ApplicationController
  before_action :set_guard_setup, only: %i[ show edit update destroy ]

  def index
    @guard_setups = GuardSetup.includes(:vocal, :guardians).order(:day_number)
  end

  def show
    @prev_guard_setup = GuardSetup.before_day(@guard_setup.day_number).first
    @next_guard_setup = GuardSetup.after_day(@guard_setup.day_number).first
    @all_guard_setups = GuardSetup.order(:day_number).pluck(:id, :day_number)
  end

  def new
    @guard_setup = GuardSetup.new
    authorize @guard_setup
  end

  def edit
    authorize @guard_setup
  end

  def create
    @guard_setup = GuardSetup.new(guard_setup_params)
    authorize @guard_setup

    respond_to do |format|
      if @guard_setup.save
        format.html { redirect_to @guard_setup, notice: t("guard_setups.notices.created") }
        format.json { render :show, status: :created, location: @guard_setup }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @guard_setup.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @guard_setup
    respond_to do |format|
      if @guard_setup.update(guard_setup_params)
        format.html { redirect_to @guard_setup, notice: t("guard_setups.notices.updated"), status: :see_other }
        format.json { render :show, status: :ok, location: @guard_setup }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @guard_setup.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @guard_setup
    @guard_setup.destroy!

    respond_to do |format|
      format.html { redirect_to guard_setups_path, notice: t("guard_setups.notices.destroyed"), status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_guard_setup
    @guard_setup = GuardSetup.find(params.expect(:id))
  end

  def guard_setup_params
    params.expect(guard_setup: [ :day_number, :notes, :vocal_id, :priest_id, guardian_ids: [] ])
  end
end
