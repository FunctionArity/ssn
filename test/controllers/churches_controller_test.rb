require "test_helper"

class ChurchesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:admin_user)
    @church = churches(:one)
    sign_in @user
  end

  test "should get index" do
    get churches_url
    assert_response :success
  end

  test "should get new" do
    get new_church_url
    assert_response :success
  end

  test "should get show" do
    get church_url(@church)
    assert_response :success
  end

  test "should get edit" do
    get edit_church_url(@church)
    assert_response :success
  end

  test "should create church with name only" do
    assert_difference("Church.count") do
      post churches_url, params: { church: { name: "Nueva Parroquia" } }
    end

    assert_redirected_to church_url(Church.last)
  end

  test "should create church with all fields" do
    assert_difference("Church.count") do
      post churches_url, params: {
        church: { name: "Nueva Parroquia", phone: "4912149", address: "San Martin 100, Mendoza" }
      }
    end

    assert_redirected_to church_url(Church.last)
  end

  test "should not create church without name" do
    assert_no_difference("Church.count") do
      post churches_url, params: { church: { name: "", address: "San Martin 100" } }
    end

    assert_response :unprocessable_entity
  end

  test "should update church" do
    patch church_url(@church), params: { church: { name: "Parroquia Actualizada" } }

    assert_redirected_to church_url(@church)
    assert_equal "Parroquia Actualizada", @church.reload.name
  end

  test "should not update church without name" do
    patch church_url(@church), params: { church: { name: "" } }

    assert_response :unprocessable_entity
    assert_equal churches(:one).name, @church.reload.name
  end

  test "should destroy church" do
    assert_difference("Church.count", -1) do
      delete church_url(@church)
    end

    assert_redirected_to churches_url
  end

  test "should require authentication" do
    sign_out @user
    get churches_url
    assert_redirected_to new_user_session_path
  end

  # ---------------------------------------------------------------------------
  # Authorization — non-admin users
  # ---------------------------------------------------------------------------

  test "non-admin cannot get index" do
    sign_in users(:one)
    get churches_url
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end

  test "non-admin cannot get new" do
    sign_in users(:one)
    get new_church_url
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end

  test "non-admin cannot get show" do
    sign_in users(:one)
    get church_url(@church)
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end

  test "non-admin cannot get edit" do
    sign_in users(:one)
    get edit_church_url(@church)
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end

  test "non-admin cannot create church" do
    sign_in users(:one)
    assert_no_difference("Church.count") do
      post churches_url, params: { church: { name: "Nueva Parroquia" } }
    end
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end

  test "non-admin cannot update church" do
    sign_in users(:one)
    original_name = @church.name
    patch church_url(@church), params: { church: { name: "Parroquia Actualizada" } }
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
    assert_equal original_name, @church.reload.name
  end

  test "non-admin cannot destroy church" do
    sign_in users(:one)
    assert_no_difference("Church.count") do
      delete church_url(@church)
    end
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end
end
