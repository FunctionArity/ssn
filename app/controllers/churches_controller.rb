class ChurchesController < ApplicationController
  before_action :set_church, only: %i[ show edit update destroy ]

  def index
    authorize Church
    @churches = Church.order(:name)
  end

  def show
    authorize @church
  end

  def new
    @church = Church.new
    authorize @church
  end

  def edit
    authorize @church
  end

  def create
    @church = Church.new(church_params)
    authorize @church

    respond_to do |format|
      if @church.save
        format.html { redirect_to @church, notice: t("churches.notices.created") }
        format.json { render :show, status: :created, location: @church }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @church.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @church

    respond_to do |format|
      if @church.update(church_params)
        format.html { redirect_to @church, notice: t("churches.notices.updated"), status: :see_other }
        format.json { render :show, status: :ok, location: @church }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @church.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @church
    @church.destroy!

    respond_to do |format|
      format.html { redirect_to churches_path, notice: t("churches.notices.destroyed"), status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_church
    @church = Church.find(params.expect(:id))
  end

  def church_params
    params.expect(church: [ :name, :phone, :address ])
  end
end
