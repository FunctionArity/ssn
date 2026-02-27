require "test_helper"

class GuardSetupsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @guard_setup = guard_setups(:one)
    sign_in @user
  end

  test "should get index" do
    get guard_setups_url
    assert_response :success
  end

  test "should get new" do
    get new_guard_setup_url
    assert_response :success
  end

  test "should show guard_setup" do
    get guard_setup_url(@guard_setup)
    assert_response :success
  end

  test "should get edit" do
    get edit_guard_setup_url(@guard_setup)
    assert_response :success
  end

  test "should create guard_setup with valid parameters" do
    assert_difference("GuardSetup.count") do
      post guard_setups_url, params: {
        guard_setup: {
          day_number: 5,
          notes: "New guard setup notes",
          vocal_id: users(:one).id,
          guardian_ids: [ users(:one).id ]
        }
      }
    end

    assert_redirected_to guard_setup_url(GuardSetup.last)
  end

  test "should update guard_setup with valid parameters" do
    new_notes = "Updated notes"
    patch guard_setup_url(@guard_setup), params: {
      guard_setup: {
        day_number: @guard_setup.day_number,
        notes: new_notes,
        vocal_id: @guard_setup.vocal_id,
        guardian_ids: [ users(:one).id ]
      }
    }

    assert_redirected_to guard_setup_url(@guard_setup)
    @guard_setup.reload
    assert_equal new_notes, @guard_setup.notes
  end

  test "should destroy guard_setup" do
    assert_difference("GuardSetup.count", -1) do
      delete guard_setup_url(@guard_setup)
    end

    assert_redirected_to guard_setups_url
  end
end
