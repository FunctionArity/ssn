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

  test "index shows draggable guardian pills for admin users" do
    get guard_setups_url

    assert_response :success
    assert_select "#guard_setups[data-controller='guardian-move']"
    assert_select "span[draggable='true'][data-guardian-move-target='pill']"
    assert_select "[data-guardian-move-target='dropzone']"
  end

  test "index hides draggable guardian pills for non-admin users" do
    sign_out @user
    sign_in users(:one)

    get guard_setups_url

    assert_response :success
    assert_select "#guard_setups[data-controller='guardian-move']", false
    assert_select "span[draggable='true']", false
    assert_select "[data-guardian-move-target]", false
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

  test "move_guardian moves a guardian from one guard setup to another" do
    guardian = users(:one)
    target = guard_setups(:two)
    assert_equal [ @guard_setup ], guardian.guard_setups.to_a

    patch move_guardian_guard_setup_url(target), params: { user_id: guardian.id }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal [ target ], guardian.reload.guard_setups.to_a
    assert_includes response.body, 'target="guard_setups"'
  end

  test "move_guardian redirects for html format" do
    guardian = users(:one)
    target = guard_setups(:two)

    patch move_guardian_guard_setup_url(target), params: { user_id: guardian.id }

    assert_redirected_to guard_setups_url
    assert_equal [ target ], guardian.reload.guard_setups.to_a
  end

  test "move_guardian is a no-op when dropped on the guardian's current guard setup" do
    guardian = users(:one)

    patch move_guardian_guard_setup_url(@guard_setup), params: { user_id: guardian.id }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal [ @guard_setup ], guardian.reload.guard_setups.to_a
  end

  test "move_guardian requires admin authorization" do
    sign_out @user
    guardian = users(:one)
    sign_in guardian
    target = guard_setups(:two)

    patch move_guardian_guard_setup_url(target), params: { user_id: guardian.id }

    assert_redirected_to root_path
    assert_equal [ @guard_setup ], guardian.reload.guard_setups.to_a
  end
end
