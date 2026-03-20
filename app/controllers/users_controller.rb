class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update destroy lock unlock resend_invitation impersonate ]

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
    authorize @user
    @churches = Church.all
  end

  # GET /users/1/edit
  def edit
    authorize @user
    @churches = Church.all
  end

  # POST /users or /users.json
  def create
    authorize User.new
    @user = User.invite!(user_params.merge(skip_invitation: false), current_user)

    respond_to do |format|
      if @user.errors.empty?
        format.html { redirect_to @user, notice: t("users.notices.invited") }
        format.json { render :show, status: :created, location: @user }
      else
        @churches = Church.all
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def resend_invitation
    authorize @user
    @user.invite!(current_user)
    redirect_to @user, notice: t("users.notices.invitation_resent")
  end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    authorize @user
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
    authorize @user
    @user.lock_access!
    redirect_to @user, notice: t("users.notices.locked")
  end

  def unlock
    authorize @user
    @user.unlock_access!
    redirect_to @user, notice: t("users.notices.unlocked")
  end

  def impersonate
    authorize @user
    impersonate_user(@user)
    redirect_to root_path, notice: t("users.notices.impersonating", name: @user.full_name)
  end

  def stop_impersonating
    stop_impersonating_user
    redirect_to root_path, notice: t("users.notices.stopped_impersonating")
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    authorize @user
    @user.destroy!

    respond_to do |format|
      format.html { redirect_to users_path, notice: t("users.notices.destroyed"), status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.includes(:guard_setups, :vocal_guard_setups, :church).find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def user_params
      permitted = params.expect(user: [ :first_name, :last_name, :email, :phone, :role, :password, :password_confirmation, :church_id ])
      permitted[:church_id] = nil unless permitted[:role] == "priest"
      permitted
    end

    def update_user_params
      base = user_params.reject { |_, v| v.blank? }
      avatar = params.dig(:user, :avatar)
      avatar.present? ? base.merge(avatar: avatar) : base
    end
end
