require "test_helper"

class HealthFacilitiesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:admin_user)
    @health_facility = health_facilities(:one)
    sign_in @user
  end

  test "should get index" do
    get health_facilities_url
    assert_response :success
  end

  test "should get new" do
    get new_health_facility_url
    assert_response :success
  end

  test "should get show" do
    get health_facility_url(@health_facility)
    assert_response :success
  end

  test "should get edit" do
    get edit_health_facility_url(@health_facility)
    assert_response :success
  end

  test "should create health facility with valid params" do
    assert_difference("HealthFacility.count") do
      post health_facilities_url, params: {
        health_facility: {
          name: "Nuevo Hospital",
          address: "San Martín 100, Mendoza"
        }
      }
    end

    assert_redirected_to health_facility_url(HealthFacility.last)
  end

  test "should not create health facility without name" do
    assert_no_difference("HealthFacility.count") do
      post health_facilities_url, params: {
        health_facility: { name: "", address: "San Martín 100, Mendoza" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not create health facility without address" do
    assert_no_difference("HealthFacility.count") do
      post health_facilities_url, params: {
        health_facility: { name: "Nuevo Hospital", address: "" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should update health facility with valid params" do
    new_name = "Hospital Actualizado"
    patch health_facility_url(@health_facility), params: {
      health_facility: { name: new_name, address: @health_facility.address }
    }

    assert_redirected_to health_facility_url(@health_facility)
    @health_facility.reload
    assert_equal new_name, @health_facility.name
  end

  test "should not update health facility without name" do
    patch health_facility_url(@health_facility), params: {
      health_facility: { name: "", address: @health_facility.address }
    }

    assert_response :unprocessable_entity
  end

  test "should destroy health facility" do
    assert_difference("HealthFacility.count", -1) do
      delete health_facility_url(@health_facility)
    end

    assert_redirected_to health_facilities_url
  end

  # ---------------------------------------------------------------------------
  # Authorization — non-admin users
  # ---------------------------------------------------------------------------

  test "non-admin cannot get index" do
    sign_in users(:one)
    get health_facilities_url
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end

  test "non-admin cannot get new" do
    sign_in users(:one)
    get new_health_facility_url
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end

  test "non-admin cannot get show" do
    sign_in users(:one)
    get health_facility_url(@health_facility)
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end

  test "non-admin cannot get edit" do
    sign_in users(:one)
    get edit_health_facility_url(@health_facility)
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end

  test "non-admin cannot create health facility" do
    sign_in users(:one)
    assert_no_difference("HealthFacility.count") do
      post health_facilities_url, params: {
        health_facility: { name: "Nuevo Hospital", address: "San Martín 100, Mendoza" }
      }
    end
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end

  test "non-admin cannot update health facility" do
    sign_in users(:one)
    original_name = @health_facility.name
    patch health_facility_url(@health_facility), params: {
      health_facility: { name: "Hospital Actualizado", address: @health_facility.address }
    }
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
    assert_equal original_name, @health_facility.reload.name
  end

  test "non-admin cannot destroy health facility" do
    sign_in users(:one)
    assert_no_difference("HealthFacility.count") do
      delete health_facility_url(@health_facility)
    end
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end
end
