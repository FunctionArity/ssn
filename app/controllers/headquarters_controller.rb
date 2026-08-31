class HeadquartersController < ApplicationController
  before_action :set_headquarter, only: %i[ show edit update destroy ]

  def index
    authorize Headquarter
    @headquarters = Headquarter.order(:country, :state, :city)
  end

  def show
    authorize @headquarter
  end

  def new
    @headquarter = Headquarter.new
    authorize @headquarter
  end

  def edit
    authorize @headquarter
  end

  def create
    @headquarter = Headquarter.new(headquarter_params)
    authorize @headquarter

    respond_to do |format|
      if @headquarter.save
        format.html { redirect_to @headquarter, notice: t("headquarters.notices.created") }
        format.json { render :show, status: :created, location: @headquarter }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @headquarter.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @headquarter

    respond_to do |format|
      if @headquarter.update(headquarter_params)
        format.html { redirect_to @headquarter, notice: t("headquarters.notices.updated"), status: :see_other }
        format.json { render :show, status: :ok, location: @headquarter }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @headquarter.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @headquarter
    @headquarter.destroy!

    respond_to do |format|
      format.html { redirect_to headquarters_path, notice: t("headquarters.notices.destroyed"), status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_headquarter
    @headquarter = Headquarter.friendly.find(params.expect(:id))
  end

  def headquarter_params
    params.expect(headquarter: [ :country, :state, :city, :address, :phone, :email, :whatsapp, :web_address, :facebook, :instagram ])
  end
end
