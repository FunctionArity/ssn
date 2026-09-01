require "test_helper"

class ServicesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActionCable::TestHelper
  include ActiveJob::TestHelper

  # users(:one)           — vocal role, vocal of guards(:one), guardian of guards(:one)
  # users(:vocal_guardian) — vocal role, guardian of guards(:one) but NOT its vocal
  # users(:unrelated_vocal) — vocal role, no relationship to guards(:one)
  # users(:two)           — guardian role, no relationship to guards(:one) (is priest)
  # users(:super_admin)   — super_admin user_type, can do everything

  setup do
    @user = users(:one)
    @service = services(:one)
    sign_in @user
  end

  test "should get index" do
    get services_url
    assert_response :success
  end

  test "new without guard_id is allowed for vocal user" do
    get new_service_url
    assert_response :success
  end

  test "should get new with guard_id param" do
    get new_service_url, params: { guard_id: guards(:one).id }
    assert_response :success
  end

  test "should get show" do
    get service_url(@service)
    assert_response :success
  end

  test "should get edit" do
    get edit_service_url(@service)
    assert_response :success
  end

  test "should create service" do
    assert_difference("Service.count") do
      post services_url, params: {
        service: {
          full_name: "Carlos García",
          due_date: Date.today,
          guard_id: guards(:one).id
        }
      }
    end

    assert_redirected_to service_url(Service.last)
  end

  test "should not create service with invalid params" do
    assert_no_difference("Service.count") do
      post services_url, params: {
        service: { full_name: "", due_date: "", guard_id: guards(:one).id }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should update service" do
    patch service_url(@service), params: {
      service: { full_name: "Nombre Actualizado" }
    }

    assert_redirected_to service_url(@service)
    assert_equal "Nombre Actualizado", @service.reload.full_name
  end

  test "should not update service with invalid params" do
    patch service_url(@service), params: {
      service: { full_name: "" }
    }

    assert_response :unprocessable_entity
  end

  test "should destroy service" do
    assert_difference("Service.count", -1) do
      delete service_url(@service)
    end

    assert_redirected_to services_url
  end

  test "should complete service" do
    post complete_service_url(@service)

    assert_redirected_to service_url(@service)
    assert @service.reload.completed?
  end

  test "should complete service via turbo_stream" do
    post complete_service_url(@service), headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert @service.reload.completed?
  end

  test "should move service to a new position within its guard" do
    other = services(:completed_one)
    assert_equal 1, @service.position
    assert_equal 2, other.position

    patch move_service_url(@service), params: { position: 2 }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal 2, @service.reload.position
    assert_equal 1, other.reload.position
  end

  test "should broadcast the reordered guard services list to other devices" do
    # Only the new guard-scoped broadcast targets this stream, so a single message proves it fired.
    assert_broadcasts("guard_#{@service.guard_id}", 1) do
      perform_enqueued_jobs do
        patch move_service_url(@service), params: { position: 2 }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end
    end
  end

  test "should additionally broadcast the services grid when the guard is today's open guard" do
    guard = guards(:one)
    guard.update!(due_date: Date.current, status: :open)

    # 3 jobs: the service's own after_update_commit broadcast, the guard-scoped list, and the services grid.
    assert_enqueued_jobs 3, only: Turbo::Streams::ActionBroadcastJob do
      patch move_service_url(@service), params: { position: 2 }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
  end

  test "should not broadcast the services grid when the guard is not today's open guard" do
    # 2 jobs: the service's own after_update_commit broadcast and the guard-scoped list (no services grid).
    assert_enqueued_jobs 2, only: Turbo::Streams::ActionBroadcastJob do
      patch move_service_url(@service), params: { position: 2 }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
  end

  test "should move service and replace the services index grid when context is services_index" do
    other = services(:completed_one)

    patch move_service_url(@service), params: { position: 2, context: "services_index" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal 2, @service.reload.position
    assert_equal 1, other.reload.position
    assert_includes response.body, 'target="services"'
  end

  test "should get pdf" do
    get pdf_service_url(@service)

    assert_response :success
    assert_equal "application/pdf", response.media_type
  end

  test "should set created_by to current user on create" do
    post services_url, params: {
      service: { full_name: "Test User", due_date: Date.today, guard_id: guards(:one).id }
    }

    assert_equal @user, Service.last.created_by
  end

  test "should require authentication" do
    sign_out @user
    get services_url
    assert_redirected_to new_user_session_path
  end

  # ---------------------------------------------------------------------------
  # Policy tests for new
  # ---------------------------------------------------------------------------

  test "new allowed for guardian of the guard" do
    sign_in users(:vocal_guardian)
    get new_service_url, params: { guard_id: guards(:one).id }
    assert_response :success
  end

  test "new allowed for super_admin" do
    sign_in users(:super_admin)
    get new_service_url, params: { guard_id: guards(:one).id }
    assert_response :success
  end

  test "new allowed for any vocal user" do
    sign_in users(:unrelated_vocal)
    get new_service_url, params: { guard_id: guards(:one).id }
    assert_response :success
  end

  test "new forbidden for non-vocal user unrelated to the guard" do
    sign_in users(:two)
    get new_service_url, params: { guard_id: guards(:one).id }
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Policy tests for create
  # ---------------------------------------------------------------------------

  test "create allowed for guardian of the guard" do
    sign_in users(:vocal_guardian)
    assert_difference("Service.count") do
      post services_url, params: {
        service: { full_name: "Test User", due_date: Date.today, guard_id: guards(:one).id }
      }
    end
    assert_redirected_to service_url(Service.last)
  end

  test "create allowed for super_admin" do
    sign_in users(:super_admin)
    assert_difference("Service.count") do
      post services_url, params: {
        service: { full_name: "Test User", due_date: Date.today, guard_id: guards(:one).id }
      }
    end
    assert_redirected_to service_url(Service.last)
  end

  test "create allowed for any vocal user" do
    sign_in users(:unrelated_vocal)
    assert_difference("Service.count") do
      post services_url, params: {
        service: { full_name: "Test User", due_date: Date.today, guard_id: guards(:one).id }
      }
    end
    assert_redirected_to service_url(Service.unscoped.last)
  end

  test "create forbidden for non-vocal user unrelated to the guard" do
    sign_in users(:two)
    assert_no_difference("Service.count") do
      post services_url, params: {
        service: { full_name: "Test User", due_date: Date.today, guard_id: guards(:one).id }
      }
    end
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Policy tests for edit
  # ---------------------------------------------------------------------------

  test "edit allowed for vocal of the guard" do
    get edit_service_url(@service)
    assert_response :success
  end

  test "edit allowed for guardian of the guard" do
    sign_in users(:vocal_guardian)
    get edit_service_url(@service)
    assert_response :success
  end

  test "edit allowed for super_admin" do
    sign_in users(:super_admin)
    get edit_service_url(@service)
    assert_response :success
  end

  test "edit allowed for any vocal user" do
    sign_in users(:unrelated_vocal)
    get edit_service_url(@service)
    assert_response :success
  end

  test "edit forbidden for non-vocal user unrelated to the guard" do
    sign_in users(:two)
    get edit_service_url(@service)
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Policy tests for update
  # ---------------------------------------------------------------------------

  test "update allowed for vocal of the guard" do
    patch service_url(@service), params: { service: { full_name: "Updated" } }
    assert_redirected_to service_url(@service)
  end

  test "update allowed for guardian of the guard" do
    sign_in users(:vocal_guardian)
    patch service_url(@service), params: { service: { full_name: "Updated" } }
    assert_redirected_to service_url(@service)
  end

  test "update allowed for super_admin" do
    sign_in users(:super_admin)
    patch service_url(@service), params: { service: { full_name: "Updated" } }
    assert_redirected_to service_url(@service)
  end

  test "update allowed for any vocal user" do
    sign_in users(:unrelated_vocal)
    patch service_url(@service), params: { service: { full_name: "Updated" } }
    assert_redirected_to service_url(@service)
  end

  test "update forbidden for non-vocal user unrelated to the guard" do
    sign_in users(:two)
    patch service_url(@service), params: { service: { full_name: "Updated" } }
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Policy tests for destroy
  # ---------------------------------------------------------------------------

  test "destroy allowed for vocal of the guard" do
    assert_difference("Service.count", -1) do
      delete service_url(@service)
    end
    assert_redirected_to services_url
  end

  test "destroy allowed for guardian of the guard" do
    sign_in users(:vocal_guardian)
    assert_difference("Service.count", -1) do
      delete service_url(@service)
    end
    assert_redirected_to services_url
  end

  test "destroy allowed for super_admin" do
    sign_in users(:super_admin)
    assert_difference("Service.count", -1) do
      delete service_url(@service)
    end
    assert_redirected_to services_url
  end

  test "destroy allowed for any vocal user" do
    sign_in users(:unrelated_vocal)
    assert_difference("Service.count", -1) do
      delete service_url(@service)
    end
    assert_redirected_to services_url
  end

  test "destroy forbidden for non-vocal user unrelated to the guard" do
    sign_in users(:two)
    assert_no_difference("Service.count") do
      delete service_url(@service)
    end
    assert_redirected_to root_path
  end
end
