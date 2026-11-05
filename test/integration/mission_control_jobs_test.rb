require "test_helper"

class MissionControlJobsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "super admins can open the jobs dashboard" do
    sign_in users(:super_admin)

    get "/jobs"

    assert_response :success
  end

  test "other users don't find it" do
    sign_in users(:one)

    get "/jobs"

    assert_response :not_found
  end

  test "signed-out visitors are sent to sign in" do
    get "/jobs"

    # A path, since url helpers called after a request into the engine get its /jobs mount point.
    assert_redirected_to "/auth/sign_in"
  end
end
