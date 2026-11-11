# Where Google sends users back after they pick their account (POST /auth/auth/google_oauth2 starts it).
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    user = User.from_google(request.env["omniauth.auth"])

    if user
      # Devise refuses locked users and pending invitations here, with its own message.
      sign_in_and_redirect user, event: :authentication
      set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
    else
      redirect_to new_user_session_path, alert: t("devise.omniauth_callbacks.no_account")
    end
  end

  # Cancelled on Google, or Google refused: Devise's default message shows the raw reason, like "access_denied".
  def failure
    redirect_to new_user_session_path, alert: t("devise.omniauth_callbacks.google_failure")
  end
end
