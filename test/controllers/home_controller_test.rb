require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "should get index as guest" do
    get root_url
    assert_response :success
  end

  test "should get index as logged in user" do
    sign_in users(:one)
    get root_url
    assert_response :success
  end

  test "shows login button when not signed in" do
    get root_url
    assert_select "a[href=?]", new_user_session_path, text: "Iniciar sesión"
  end

  test "hides login button when signed in" do
    sign_in users(:one)
    get root_url
    assert_select "a[href=?]", new_user_session_path, count: 0
  end

  test "shows navbar when signed in" do
    sign_in users(:one)
    get root_url
    assert_select "nav"
  end

  test "hides navbar when not signed in" do
    get root_url
    assert_select "nav", count: 0
  end
end
