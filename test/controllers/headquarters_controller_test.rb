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
    sign_in users(:super_admin)
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
    sign_in users(:super_admin)

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
    sign_in users(:super_admin)

    assert_no_difference("Headquarter.count") do
      post headquarters_url, params: {
        headquarter: { country: "", state: "", city: "", address: "", phone: "351 555 1234" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not create headquarter without a contact method" do
    sign_in users(:super_admin)

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
    sign_in users(:super_admin)

    assert_difference("Headquarter.count", -1) do
      delete headquarter_url(headquarters(:two))
    end

    assert_redirected_to headquarters_url
  end

  test "a headquarter with users, guards or services is kept" do
    sign_in users(:super_admin)

    assert_no_difference("Headquarter.count") do
      delete headquarter_url(@headquarter)
    end

    assert_redirected_to headquarter_url(@headquarter)
    assert_equal I18n.t("headquarters.notices.not_destroyed"), flash[:alert]
  end

  test "a sede with users is kept when deleted from another sede" do
    sign_in users(:super_admin)
    ActsAsTenant.with_tenant(headquarters(:two)) do
      User.create!(email: "vocal@quito.test", first_name: "Ana", last_name: "Quiteña", role: :vocal, password: "password123")
    end

    assert_no_difference("Headquarter.count") do
      delete headquarter_url(headquarters(:two))
    end

    assert_redirected_to headquarter_url(headquarters(:two))
    assert_equal I18n.t("headquarters.notices.not_destroyed"), flash[:alert]
  end

  test "admins edit their own sede, but don't create or delete sedes" do
    get headquarters_url
    assert_select "a[href='#{new_headquarter_path}']", count: 0

    get new_headquarter_url
    assert_redirected_to root_url

    get headquarter_url(@headquarter)
    assert_select "a[href='#{edit_headquarter_path(@headquarter)}']"
    assert_select "form[action='#{headquarter_path(@headquarter)}'] input[name='_method'][value='delete']", count: 0

    assert_no_difference("Headquarter.count") { delete headquarter_url(headquarters(:two)) }
  end

  test "admins only edit their own sede" do
    other = headquarters(:two)

    get headquarter_url(other)
    assert_select "a[href='#{edit_headquarter_path(other)}']", count: 0
    assert_select "form[action='#{headquarter_path(other)}'] input[name='_method'][value='delete']", count: 0

    get edit_headquarter_url(other)
    assert_redirected_to root_url

    patch headquarter_url(other), params: { headquarter: { city: "Otra" } }
    assert_not_equal "Otra", other.reload.city

    assert_no_difference("Headquarter.count") { delete headquarter_url(other) }
  end

  # ---------------------------------------------------------------------------
  # Authorization — non-admin users
  # ---------------------------------------------------------------------------

  test "index shows new button to super admins" do
    sign_in users(:super_admin)
    get headquarters_url
    assert_select "a[href='#{new_headquarter_path}']"
  end

  test "non-admin can get index without new button" do
    sign_in users(:one)
    get headquarters_url
    assert_response :success
    assert_select "a[href='#{new_headquarter_path}']", false
  end

  test "non-admin cannot get new" do
    sign_in users(:one)
    get new_headquarter_url
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end

  test "show has a copy button with the headquarter info" do
    get headquarter_url(@headquarter)

    assert_select "button[data-controller='clipboard']" do |buttons|
      text = buttons.first["data-clipboard-text-value"]
      assert_includes text, "#{@headquarter.city}, #{@headquarter.state}, #{@headquarter.country}"
      assert_includes text, @headquarter.address
      assert_includes text, @headquarter.email
    end
  end

  test "show displays edit and destroy actions to super admins" do
    sign_in users(:super_admin)
    get headquarter_url(@headquarter)
    assert_select "a[href='#{edit_headquarter_path(@headquarter)}']"
    assert_select "form[action='#{headquarter_path(@headquarter)}'] input[name='_method'][value='delete']"
  end

  test "non-admin can get show without edit and destroy actions" do
    sign_in users(:one)
    get headquarter_url(@headquarter)
    assert_response :success
    assert_select "a[href='#{edit_headquarter_path(@headquarter)}']", false
    assert_select "form[action='#{headquarter_path(@headquarter)}'] input[name='_method'][value='delete']", false
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
