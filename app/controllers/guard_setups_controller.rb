class GuardSetupsController < ApplicationController
  before_action :set_guard_setup, only: %i[ show edit update destroy ]

  def index
    @guard_setups = GuardSetup.includes(:vocal, :priest, :guardians).order(:day_number)
  end

  def show
  end

  def new
    @guard_setup = GuardSetup.new
  end

  def edit
  end

  def create
    @guard_setup = GuardSetup.new(guard_setup_params)

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
