require "test_helper"

class Api::V1::SessionsControllerTest < ActionDispatch::IntegrationTest
  include ApiTestHelper
  include GoogleIdTokenTestHelper

  test "signs in with email and password and returns a token for the API" do
    post api_v1_session_url, params: { email: " Pablo@Rodriguez.com ", password: "password123" }, as: :json

    assert_response :created
    assert_equal users(:one).id, json.dig("user", "id")
    assert_equal headquarters(:one).id, json.dig("headquarter", "id")
    assert_equal users(:one), ApiToken.user_for(json["token"])
    assert_equal 1, users(:one).reload.sign_in_count
  end

  test "refuses a wrong password and counts the failed attempt" do
    post api_v1_session_url, params: { email: "pablo@rodriguez.com", password: "wrong" }, as: :json

    assert_response :unauthorized
    assert_equal "Email o contraseña inválidos.", json["error"]
    assert_nil json["token"]
    assert_equal 1, users(:one).reload.failed_attempts
  end

  test "refuses an unknown email with the same message" do
    post api_v1_session_url, params: { email: "nobody@example.test", password: "password123" }, as: :json

    assert_response :unauthorized
    assert_equal "Email o contraseña inválidos.", json["error"]
  end

  test "refuses a locked user, even with the right password" do
    users(:one).lock_access!(send_instructions: false)

    post api_v1_session_url, params: { email: "pablo@rodriguez.com", password: "password123" }, as: :json

    assert_response :unauthorized
    assert_equal "Tu cuenta está bloqueada.", json["error"]
  end

  test "signs in a user of another sede, in their own sede" do
    quito = headquarters(:two)
    user = ActsAsTenant.with_tenant(quito) do
      User.create!(email: "ana@quito.test", first_name: "Ana", last_name: "Quiteña", password: "password123")
    end

    post api_v1_session_url, params: { email: "ana@quito.test", password: "password123" }, as: :json

    assert_response :created
    assert_equal user.id, json.dig("user", "id")
    assert_equal quito.id, json.dig("headquarter", "id")
  end

  test "signs in with a Google ID token of an existing user" do
    with_google_keys do
      post google_api_v1_session_url, params: { credential: google_id_token }, as: :json
    end

    assert_response :created
    assert_equal users(:one), ApiToken.user_for(json["token"])
  end

  test "refuses a Google account nobody was invited with" do
    with_google_keys do
      post google_api_v1_session_url, params: { credential: google_id_token(email: "stranger@example.test") }, as: :json
    end

    assert_response :unauthorized
    assert_equal I18n.t("devise.omniauth_callbacks.no_account"), json["error"]
  end

  test "refuses a Google token that doesn't verify" do
    with_google_keys do
      post google_api_v1_session_url, params: { credential: "not-a-token" }, as: :json
    end

    assert_response :unauthorized
    assert_equal I18n.t("devise.omniauth_callbacks.google_failure"), json["error"]
  end

  test "refuses a locked user signing in with Google" do
    users(:one).lock_access!(send_instructions: false)

    with_google_keys do
      post google_api_v1_session_url, params: { credential: google_id_token }, as: :json
    end

    assert_response :unauthorized
    assert_equal "Tu cuenta está bloqueada.", json["error"]
  end

  test "signing out revokes the token, and only that one" do
    signed_out = api_headers(users(:one))
    other_device = api_headers(users(:one))

    delete api_v1_session_url, headers: signed_out, as: :json
    assert_response :no_content

    get api_v1_me_url, headers: signed_out, as: :json
    assert_response :unauthorized

    get api_v1_me_url, headers: other_device, as: :json
    assert_response :success
  end

  test "signing out needs a valid token" do
    delete api_v1_session_url, as: :json
    assert_response :unauthorized

    delete api_v1_session_url, headers: { "Authorization" => "Bearer not-a-token" }, as: :json
    assert_response :unauthorized
  end
end
