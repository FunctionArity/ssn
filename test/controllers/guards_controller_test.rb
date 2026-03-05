require "test_helper"

class GuardsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @guard = guards(:one)
    sign_in @user
  end

  test "should get index" do
    get guards_url
    assert_response :success
  end

  test "should get show" do
    get guard_url(@guard)
    assert_response :success
  end

  test "should get edit" do
    get edit_guard_url(@guard)
    assert_response :success
  end

  test "should get new without guard_setup_id" do
    get new_guard_url
    assert_response :success
  end

  test "should get new with guard_setup_id and render the form" do
    get new_guard_url, params: { guard_setup_id: guard_setups(:one).id }
    assert_response :success
  end

  test "should return not found when guard_setup_id does not exist" do
    get new_guard_url, params: { guard_setup_id: -1 }
    assert_response :not_found
  end

  test "should create guard with valid parameters" do
    assert_difference("Guard.count") do
      post guards_url, params: {
        guard: {
          day_number: 5,
          due_date: Date.today,
          notes: "New guard notes",
          vocal_id: users(:one).id,
          priest_id: users(:two).id,
          guard_setup_id: guard_setups(:one).id,
          guardian_ids: [ users(:one).id ]
        }
      }
    end

    assert_redirected_to guard_url(Guard.last)
  end

  test "should not create guard without guardians" do
    assert_no_difference("Guard.count") do
      post guards_url, params: {
        guard: {
          day_number: 5,
          due_date: Date.today,
          vocal_id: users(:one).id,
          priest_id: users(:two).id,
          guard_setup_id: guard_setups(:one).id,
          guardian_ids: []
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should update guard with valid parameters" do
    new_notes = "Updated notes"
    patch guard_url(@guard), params: {
      guard: {
        day_number: @guard.day_number,
        notes: new_notes,
        vocal_id: @guard.vocal_id,
        priest_id: @guard.priest_id,
        guardian_ids: [ users(:one).id ]
      }
    }

    assert_redirected_to guard_url(@guard)
    @guard.reload
    assert_equal new_notes, @guard.notes
  end

  test "should not update guard with invalid params" do
    patch guard_url(@guard), params: {
      guard: {
        day_number: nil,
        vocal_id: @guard.vocal_id,
        priest_id: @guard.priest_id,
        guardian_ids: [ users(:one).id ]
      }
    }

    assert_response :unprocessable_entity
    assert_equal 1, @guard.reload.day_number
  end

  test "should destroy guard and its services" do
    @guard.services.create!(full_name: "Test", due_date: Date.today, created_by: @user)
    services_count = @guard.services.count

    assert_difference("Service.count", -services_count) do
      assert_difference("Guard.count", -1) do
        delete guard_url(@guard)
      end
    end

    assert_redirected_to guards_url
  end

  test "should destroy guard" do
    assert_difference("Guard.count", -1) do
      delete guard_url(@guard)
    end

    assert_redirected_to guards_url
  end

  test "should close an open guard" do
    assert @guard.open?

    post close_guard_url(@guard)

    assert_redirected_to guard_url(@guard)
    assert @guard.reload.closed?
  end

  test "should not close an already closed guard" do
    @guard.closed!

    post close_guard_url(@guard)

    assert_redirected_to guard_url(@guard)
    assert @guard.reload.closed?
  end
end
