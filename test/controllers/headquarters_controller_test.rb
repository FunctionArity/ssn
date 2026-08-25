require "test_helper"

class HeadquartersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:admin_user)
    @headquarter = headquarters(:one)
    sign_in @user
  end

  test "should get index" do
    get headquarters_url
    assert_response :success
  end

  test "should get new" do
    get new_headquarter_url
    assert_response :success
  end

  test "should get show" do
    get headquarter_url(@headquarter)
    assert_response :success
  end

  test "should get edit" do
    get edit_headquarter_url(@headquarter)
    assert_response :success
  end

  test "should create headquarter with valid params" do
    assert_difference("Headquarter.count") do
      post headquarters_url, params: {
        headquarter: {
          country: "Argentina",
          state: "Córdoba",
          city: "Córdoba",
          address: "Av. Colón 1500",
          phone: "351 555 1234"
        }
      }
    end

    assert_redirected_to headquarter_url(Headquarter.last)
  end

  test "should not create headquarter without mandatory fields" do
    assert_no_difference("Headquarter.count") do
      post headquarters_url, params: {
        headquarter: { country: "", state: "", city: "", address: "", phone: "351 555 1234" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not create headquarter without a contact method" do
    assert_no_difference("Headquarter.count") do
      post headquarters_url, params: {
        headquarter: {
          country: "Argentina",
          state: "Córdoba",
          city: "Córdoba",
          address: "Av. Colón 1500"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should update headquarter with valid params" do
    new_city = "San Rafael"
    patch headquarter_url(@headquarter), params: {
      headquarter: { city: new_city }
    }

    assert_redirected_to headquarter_url(@headquarter)
    @headquarter.reload
    assert_equal new_city, @headquarter.city
  end

  test "should not update headquarter without city" do
    patch headquarter_url(@headquarter), params: {
      headquarter: { city: "" }
    }

    assert_response :unprocessable_entity
  end

  test "should destroy headquarter" do
    assert_difference("Headquarter.count", -1) do
      delete headquarter_url(@headquarter)
    end

    assert_redirected_to headquarters_url
  end

  # ---------------------------------------------------------------------------
  # Authorization — non-admin users
  # ---------------------------------------------------------------------------

  test "non-admin cannot get index" do
    sign_in users(:one)
    get headquarters_url
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end

  test "non-admin cannot get new" do
    sign_in users(:one)
    get new_headquarter_url
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end

  test "non-admin cannot get show" do
    sign_in users(:one)
    get headquarter_url(@headquarter)
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end

  test "non-admin cannot get edit" do
    sign_in users(:one)
    get edit_headquarter_url(@headquarter)
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end

  test "non-admin cannot create headquarter" do
    sign_in users(:one)
    assert_no_difference("Headquarter.count") do
      post headquarters_url, params: {
        headquarter: {
          country: "Argentina",
          state: "Córdoba",
          city: "Córdoba",
          address: "Av. Colón 1500",
          phone: "351 555 1234"
        }
      }
    end
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end

  test "non-admin cannot update headquarter" do
    sign_in users(:one)
    original_city = @headquarter.city
    patch headquarter_url(@headquarter), params: { headquarter: { city: "San Rafael" } }
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
    assert_equal original_city, @headquarter.reload.city
  end

  test "non-admin cannot destroy headquarter" do
    sign_in users(:one)
    assert_no_difference("Headquarter.count") do
      delete headquarter_url(@headquarter)
    end
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end
end
