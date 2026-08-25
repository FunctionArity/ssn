class HealthFacilitiesController < ApplicationController
  before_action :set_health_facility, only: %i[ show edit update destroy ]

  def index
    authorize HealthFacility
    @health_facilities = HealthFacility.order(:name)
  end

  def show
    authorize @health_facility
  end

  def new
    @health_facility = HealthFacility.new
    authorize @health_facility
  end

  def edit
    authorize @health_facility
  end

  def create
    @health_facility = HealthFacility.new(health_facility_params)
    authorize @health_facility

    respond_to do |format|
      if @health_facility.save
        format.html { redirect_to @health_facility, notice: t("health_facilities.notices.created") }
        format.json { render :show, status: :created, location: @health_facility }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @health_facility.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @health_facility

    respond_to do |format|
      if @health_facility.update(health_facility_params)
        format.html { redirect_to @health_facility, notice: t("health_facilities.notices.updated"), status: :see_other }
        format.json { render :show, status: :ok, location: @health_facility }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @health_facility.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @health_facility
    @health_facility.destroy!

    respond_to do |format|
      format.html { redirect_to health_facilities_path, notice: t("health_facilities.notices.destroyed"), status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_health_facility
    @health_facility = HealthFacility.find(params.expect(:id))
  end

  def health_facility_params
    params.expect(health_facility: [ :name, :address ])
  end
end
