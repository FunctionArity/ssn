require "test_helper"

class PriestAssignmentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:admin_user)
    sign_in @user
  end

  test "should get index" do
    get priest_setups_url
    assert_response :success
  end

  test "should require authentication" do
    sign_out @user
    get priest_setups_url
    assert_response :redirect
  end
end
