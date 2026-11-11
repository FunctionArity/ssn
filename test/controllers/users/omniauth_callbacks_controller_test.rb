require "test_helper"

class Users::OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
    @user = users(:one)
  end

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end

  test "signs in the user with that verified Google email" do
    sign_in_with_google email: @user.email.upcase

    assert_redirected_to root_path
    assert_equal I18n.t("devise.omniauth_callbacks.success", kind: "Google"), flash[:notice]
    follow_redirect!
    get services_url
    assert_response :success
    assert_not_nil @user.reload.current_sign_in_at
  end

  test "doesn't sign in an email without an account" do
    assert_no_difference -> { User.count } do
      sign_in_with_google email: "nobody@example.test"
    end

    assert_redirected_to new_user_session_path
    assert_equal I18n.t("devise.omniauth_callbacks.no_account"), flash[:alert]
    assert_signed_out
  end

  test "doesn't trust an email Google hasn't verified" do
    sign_in_with_google email: @user.email, verified: false

    assert_redirected_to new_user_session_path
    assert_signed_out
  end

  test "locked users stay out" do
    @user.lock_access!(send_instructions: false)

    sign_in_with_google email: @user.email

    assert_redirected_to new_user_session_path
    assert_equal I18n.t("devise.failure.locked"), flash[:alert]
    assert_signed_out
  end

  test "users with a pending invitation stay out until they accept it" do
    invited = User.invite!({ email: "invited@example.test", first_name: "Ana", last_name: "Invitada" }, users(:super_admin)) { |user| user.skip_invitation = true }

    sign_in_with_google email: invited.email

    assert_redirected_to new_user_session_path
    assert_equal I18n.t("devise.failure.invited"), flash[:alert]
    assert_signed_out
  end

  test "cancelling on Google goes back to sign in with a message" do
    OmniAuth.config.mock_auth[:google_oauth2] = :access_denied
    silence_omniauth_logger do
      post user_google_oauth2_omniauth_authorize_path
      follow_redirect! # OmniAuth's failure endpoint, handled by the controller's failure action
    end

    assert_redirected_to new_user_session_path
    assert_equal I18n.t("devise.omniauth_callbacks.google_failure"), flash[:alert]
  end

  test "the sign in page has the Google button, which posts outside Turbo" do
    get new_user_session_path

    assert_select "form[action=?][method=post][data-turbo=false] button", user_google_oauth2_omniauth_authorize_path, text: I18n.t("devise_views.sessions.google")
  end

  test "starting the sign in with a GET isn't allowed" do
    get user_google_oauth2_omniauth_authorize_path

    assert_response :not_found
  end

  private

  def sign_in_with_google(email:, verified: true)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "123",
      info: { email: email }, extra: { raw_info: { email_verified: verified } }
    )
    post user_google_oauth2_omniauth_authorize_path
    follow_redirect!
  end

  def assert_signed_out
    get services_url
    assert_redirected_to new_user_session_path
  end

  def silence_omniauth_logger
    logger, OmniAuth.config.logger = OmniAuth.config.logger, Logger.new(nil)
    yield
  ensure
    OmniAuth.config.logger = logger
  end
end
