# The API tokens page, for super admins: they create tokens for themselves to call the JSON API (/api/v1) from Postman and the like,
# see the ones still active and revoke them. Creating and revoking update the page with Turbo Streams.
# Not while impersonating: the token would let the admin act as that user outside the app.
class PersonalAccessTokensController < ApplicationController
  before_action :require_acting_as_self
  before_action :set_tokens, only: :index

  def index
    authorize PersonalAccessToken
  end

  def create
    authorize PersonalAccessToken
    @new_token = PersonalAccessToken.generate_for(current_user)
    set_tokens

    respond_to do |format|
      format.turbo_stream
      # Without Turbo, the page itself shows the new token, since it can't be shown again later.
      format.html { render :index, status: :created }
    end
  end

  def destroy
    token = authorize policy_scope(PersonalAccessToken).find(params[:id])
    token.revoke!
    set_tokens

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to personal_access_tokens_path, notice: t(".revoked"), status: :see_other }
    end
  end

  private

  def set_tokens
    @tokens = policy_scope(PersonalAccessToken).active
  end

  def require_acting_as_self
    redirect_to root_path, alert: t("personal_access_tokens.impersonating") unless acting_as_self?
  end
end
