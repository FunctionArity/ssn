# Signs in with Google One Tap: the page gets an ID token from Google for the account the visitor picked,
# and posts it here. Same rules as the Google button: only existing users, by the email Google verified.
class Users::GoogleOneTapController < ApplicationController
  skip_before_action :authenticate_user!
  rate_limit to: 10, within: 1.minute, only: :create,
             with: -> { redirect_to new_user_session_path, alert: t("devise.omniauth_callbacks.google_failure") }

  def create
    claims = GoogleIdToken.verify(params[:credential])
    user = User.from_google_id_token(claims) if claims

    if user
      # Devise refuses locked users and pending invitations here, with its own message.
      sign_in_and_redirect user, event: :authentication
      flash[:notice] = t("devise.omniauth_callbacks.success", kind: "Google") if is_navigational_format?
    else
      redirect_to new_user_session_path, alert: t(claims ? "devise.omniauth_callbacks.no_account" : "devise.omniauth_callbacks.google_failure")
    end
  end
end
