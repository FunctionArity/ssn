class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update destroy lock unlock ]

  # GET /users or /users.json
  def index
    @users_by_role = User.order(:last_name, :first_name).group_by(&:role)
  end

  # GET /users/1 or /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
    @churches = Church.all
  end

  # GET /users/1/edit
  def edit
    @churches = Church.all
  end

  # POST /users or /users.json
  def create
    @user = User.new(user_params)
    @user.password = SecureRandom.hex(12) if user_params[:password].blank?

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: t("users.notices.created") }
        format.json { render :show, status: :created, location: @user }
      else
        @churches = Church.all
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    respond_to do |format|
      if @user.update(update_user_params)
        format.html { redirect_to @user, notice: t("users.notices.updated"), status: :see_other }
        format.json { render :show, status: :ok, location: @user }
      else
        @churches = Church.all
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def lock
    @user.lock_access!
    redirect_to @user, notice: t("users.notices.locked")
  end

  def unlock
    @user.unlock_access!
    redirect_to @user, notice: t("users.notices.unlocked")
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    @user.destroy!

    respond_to do |format|
      format.html { redirect_to users_path, notice: t("users.notices.destroyed"), status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def user_params
      permitted = params.expect(user: [ :first_name, :last_name, :email, :phone, :role, :password, :password_confirmation, :church_id ])
      permitted[:church_id] = nil unless permitted[:role] == "priest"
      permitted
    end

    def update_user_params
      user_params.reject { |_, v| v.blank? }
    end
end
