require "test_helper"

# The API's tokens and the HTML app's session sign-in don't mix: each only works where it belongs.
class ApiAndHtmlSignInTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ApiTestHelper

  setup do
    @user = users(:one)
  end

  test "the HTML sign-in works as before, without handing out a token" do
    post user_session_path, params: { user: { email: @user.email, password: "password123" } }

    assert_redirected_to root_path
    assert_nil response.headers["Authorization"]
    get services_url
    assert_response :success
  end

  test "the API sign-in doesn't start a browser session" do
    post api_v1_session_url, params: { email: @user.email, password: "password123" }, as: :json

    assert_response :created
    assert_nil response.headers["Set-Cookie"]
  end

  test "a token doesn't sign anyone in to the HTML app" do
    get services_url, headers: api_headers(@user)

    assert_redirected_to new_user_session_path
  end

  test "a browser session doesn't authenticate the API" do
    sign_in @user

    get api_v1_me_url, as: :json

    assert_response :unauthorized
  end
end
