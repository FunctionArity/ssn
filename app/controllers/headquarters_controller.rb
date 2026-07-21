class HeadquartersController < ApplicationController
  before_action :set_headquarter, only: %i[ show edit update destroy ]

  def index
    @headquarters = Headquarter.order(:country, :state, :city)
  end

  def show
  end

  def new
    @headquarter = Headquarter.new
  end

  def edit
  end

  def create
    @headquarter = Headquarter.new(headquarter_params)

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
    @headquarter.destroy!

    respond_to do |format|
      format.html { redirect_to headquarters_path, notice: t("headquarters.notices.destroyed"), status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_headquarter
    @headquarter = Headquarter.find(params.expect(:id))
  end

  def headquarter_params
    params.expect(headquarter: [ :country, :state, :city, :address, :phone, :email, :whatsapp, :web_address, :facebook, :instagram ])
  end
end
