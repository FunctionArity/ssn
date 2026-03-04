require "test_helper"

class ServicesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @service = services(:one)
    sign_in @user
  end

  test "should get index" do
    get services_url
    assert_response :success
  end

  test "should get new" do
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
end
