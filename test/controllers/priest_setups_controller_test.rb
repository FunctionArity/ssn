require "test_helper"

class PriestSetupsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @priest_setup = priest_setups(:one)
    sign_in @user
  end

  test "should get assign" do
    get assign_priest_setups_url
    assert_response :success
  end

  test "should create priest setup" do
    assert_difference("PriestSetup.count") do
      post priest_setups_url, params: {
        priest_setup: {
          priest_id: users(:priest_two).id,
          week_number: 3,
          day_of_week: 5
        }
      }
    end

    assert_redirected_to assign_priest_setups_url
  end

  test "should replace existing assignment when creating for same slot" do
    assert_no_difference("PriestSetup.count") do
      post priest_setups_url, params: {
        priest_setup: {
          priest_id: users(:priest_two).id,
          week_number: @priest_setup.week_number,
          day_of_week: @priest_setup.day_of_week
        }
      }
    end

    assert_redirected_to assign_priest_setups_url
    assert_equal users(:priest_two).id, PriestSetup.find_by(week_number: @priest_setup.week_number, day_of_week: @priest_setup.day_of_week).priest_id
  end

  test "should not create priest setup with invalid week_number" do
    assert_no_difference("PriestSetup.count") do
      post priest_setups_url, params: {
        priest_setup: {
          priest_id: users(:priest_one).id,
          week_number: 6,
          day_of_week: 1
        }
      }
    end

    assert_redirected_to assign_priest_setups_url
  end

  test "should destroy priest setup" do
    assert_difference("PriestSetup.count", -1) do
      delete priest_setup_url(@priest_setup)
    end

    assert_redirected_to assign_priest_setups_url
  end

  test "should require authentication" do
    sign_out @user
    get assign_priest_setups_url
    assert_response :redirect
  end
end
