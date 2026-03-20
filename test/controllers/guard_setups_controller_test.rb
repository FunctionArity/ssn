require "test_helper"

class GuardSetupsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:admin_user)
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

  test "should not create guard_setup without guardians" do
    assert_no_difference("GuardSetup.count") do
      post guard_setups_url, params: {
        guard_setup: {
          day_number: 5,
          vocal_id: users(:one).id,
          guardian_ids: []
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not create guard_setup without day_number" do
    assert_no_difference("GuardSetup.count") do
      post guard_setups_url, params: {
        guard_setup: {
          day_number: nil,
          vocal_id: users(:one).id,
          guardian_ids: [ users(:one).id ]
        }
      }
    end

    assert_response :unprocessable_entity
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

  test "should not update guard_setup with invalid params" do
    patch guard_setup_url(@guard_setup), params: {
      guard_setup: {
        day_number: nil,
        vocal_id: @guard_setup.vocal_id,
        guardian_ids: [ users(:one).id ]
      }
    }

    assert_response :unprocessable_entity
    assert_equal 1, @guard_setup.reload.day_number
  end

  test "should destroy guard_setup and cascade to guards and services" do
    guards_count   = @guard_setup.guards.count
    services_count = Service.where(guard: @guard_setup.guards).count

    assert_difference("GuardSetup.count", -1) do
      assert_difference("Guard.count", -guards_count) do
        assert_difference("Service.count", -services_count) do
          delete guard_setup_url(@guard_setup)
        end
      end
    end

    assert_redirected_to guard_setups_url
  end

  test "should destroy guard_setup" do
    assert_difference("GuardSetup.count", -1) do
      delete guard_setup_url(@guard_setup)
    end

    assert_redirected_to guard_setups_url
  end
end
