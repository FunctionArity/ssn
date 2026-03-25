class HeadquartersController < ApplicationController
  before_action :set_headquarters, only: %i[ show edit update destroy ]

  def index
    @headquarters = Headquarter.includes(:president).order(:name)
    authorize @headquarters
  end

  def show
    authorize @headquarter
  end

  def new
    @headquarter = Headquarter.new
    authorize @headquarter
    load_users
  end

  def edit
    authorize @headquarter
    load_users
  end

  def create
    @headquarter = Headquarter.new(headquarter_params)
    authorize @headquarter

    respond_to do |format|
      if @headquarter.save
        format.html { redirect_to headquarter_path(@headquarter), notice: t("headquarters.notices.created") }
        format.json { render :show, status: :created, location: @headquarter }
      else
        load_users
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @headquarter.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @headquarter
    respond_to do |format|
      if @headquarter.update(headquarter_params)
        format.html { redirect_to headquarter_path(@headquarter), notice: t("headquarters.notices.updated"), status: :see_other }
        format.json { render :show, status: :ok, location: @headquarter }
      else
        load_users
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

  def set_headquarters
    @headquarter = Headquarter.find(params.expect(:id))
  end

  def load_users
    @users = User.order(:last_name, :first_name)
  end

  def headquarter_params
    params.expect(headquarter: [ :name, :president_id ])
  end
end
