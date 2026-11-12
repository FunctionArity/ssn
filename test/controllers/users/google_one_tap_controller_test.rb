require "test_helper"

class Users::GoogleOneTapControllerTest < ActionDispatch::IntegrationTest
  include GoogleIdTokenTestHelper

  setup do
    @user = users(:one)
  end

  test "signs in the user with that verified Google email" do
    with_google_keys { post google_one_tap_path, params: { credential: google_id_token(email: @user.email.upcase) } }

    assert_redirected_to root_path
    assert_equal I18n.t("devise.omniauth_callbacks.success", kind: "Google"), flash[:notice]
    get services_url
    assert_response :success
  end

  test "doesn't sign in an email without an account, nor one Google hasn't verified" do
    with_google_keys { post google_one_tap_path, params: { credential: google_id_token(email: "nobody@example.test") } }
    assert_redirected_to new_user_session_path
    assert_equal I18n.t("devise.omniauth_callbacks.no_account"), flash[:alert]

    with_google_keys { post google_one_tap_path, params: { credential: google_id_token(email: @user.email, email_verified: false) } }
    assert_redirected_to new_user_session_path
    assert_signed_out
  end

  test "an invalid token doesn't sign anyone in" do
    with_google_keys { post google_one_tap_path, params: { credential: google_id_token(email: @user.email, aud: "another-app") } }

    assert_redirected_to new_user_session_path
    assert_equal I18n.t("devise.omniauth_callbacks.google_failure"), flash[:alert]
    assert_signed_out
  end

  test "locked users stay out" do
    @user.lock_access!(send_instructions: false)

    with_google_keys { post google_one_tap_path, params: { credential: google_id_token(email: @user.email) } }

    assert_redirected_to new_user_session_path
    assert_equal I18n.t("devise.failure.locked"), flash[:alert]
    assert_signed_out
  end

  test "the home page offers One Tap to signed out visitors only" do
    with_google_keys do
      get root_path
      assert_select "form[action=?][hidden][data-turbo=false][data-controller=google-one-tap][data-google-one-tap-client-id-value=?]",
                    google_one_tap_path, GOOGLE_CLIENT_ID do
        assert_select "input[name=credential][data-google-one-tap-target=credential]"
      end

      sign_in_as @user
      get root_path
      assert_select "[data-controller=google-one-tap]", count: 0
    end
  end

  test "the home page has no One Tap without a Google client" do
    replacing(GoogleIdToken, :client_id, -> { nil }) { get root_path }

    assert_select "[data-controller=google-one-tap]", count: 0
  end

  test "more than 10 tries a minute from one address are turned away" do
    tries = 0
    # The test environment's cache counts nothing, so the count is kept here.
    replacing(Users::GoogleOneTapController.cache_store, :increment, ->(*_args, **_options) { tries += 1 }) do
      with_google_keys do
        10.times { post google_one_tap_path, params: { credential: "not-a-token" } }
        post google_one_tap_path, params: { credential: google_id_token(email: @user.email) }
      end
    end

    assert_redirected_to new_user_session_path
    assert_equal I18n.t("devise.omniauth_callbacks.google_failure"), flash[:alert]
    assert_signed_out
  end

  private

  def sign_in_as(user)
    post google_one_tap_path, params: { credential: google_id_token(email: user.email) }
  end

  def assert_signed_out
    get services_url
    assert_redirected_to new_user_session_path
  end
end
