require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:super_admin)
    sign_in @user
  end

  test "should get index" do
    get users_url
    assert_response :success
  end

  test "should get new" do
    get new_user_url
    assert_response :success
  end

  test "should create user and send invitation email" do
    assert_difference([ "User.count", "ActionMailer::Base.deliveries.size" ]) do
      post users_url, params: { user: { email: Faker::Internet.email, first_name: "New", last_name: "User", phone: "1111111111" } }
    end

    assert_redirected_to user_url(User.last)
    assert_nil User.last.invitation_accepted_at
  end

  test "should not create user with missing required fields" do
    assert_no_difference("User.count") do
      post users_url, params: { user: { email: "", first_name: "", last_name: "", phone: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "should not create user with duplicate email" do
    assert_no_difference("User.count") do
      post users_url, params: { user: { email: @user.email, first_name: "Dup", last_name: "User", phone: "9999999999" } }
    end

    assert_response :unprocessable_entity
  end

  test "should show user" do
    get user_url(@user)
    assert_response :success
  end

  test "show displays active status when invitation accepted" do
    get user_url(@user)
    assert_select "span", text: /Activo/
  end

  test "show displays invitation pending badge when not yet accepted" do
    pending_user = User.invite!({ email: "pending@test.com", first_name: "Pending", last_name: "User", headquarter_id: headquarters(:one).id }, @user)
    get user_url(pending_user)
    assert_select "span", text: /Invitación pendiente/
  end

  test "should resend invitation email" do
    pending_user = User.invite!({ email: "pending2@test.com", first_name: "Pending", last_name: "User", headquarter_id: headquarters(:one).id }, @user)
    assert_difference("ActionMailer::Base.deliveries.size") do
      post resend_invitation_user_url(pending_user)
    end
    assert_redirected_to user_url(pending_user)
  end

  test "registration route is not accessible" do
    sign_out @user
    get "/auth/sign_up"
    assert_response :not_found
  end

  test "invitation accept route is accessible when not signed in" do
    pending_user = User.invite!({ email: "pending3@test.com", first_name: "Pending", last_name: "User", headquarter_id: headquarters(:one).id }, @user)
    sign_out @user
    get accept_user_invitation_url(invitation_token: pending_user.raw_invitation_token)
    assert_response :success
  end

  test "should get edit" do
    get edit_user_url(@user)
    assert_response :success
  end

  test "should update user" do
    patch user_url(@user), params: { user: { email: @user.email, first_name: @user.first_name, last_name: @user.last_name, phone: @user.phone } }
    assert_redirected_to user_url(@user)
  end

  test "should not update user with duplicate email" do
    patch user_url(@user), params: { user: { email: users(:agustin).email } }
    assert_response :unprocessable_entity
  end

  test "should require authentication" do
    sign_out @user
    get users_url
    assert_redirected_to new_user_session_path
  end

  test "should destroy user" do
    assert_difference("User.count", -1) do
      delete user_url(users(:agustin))
    end

    assert_redirected_to users_url
  end

  test "should assign church when creating a priest" do
    church = churches(:one)
    assert_difference("User.count") do
      post users_url, params: {
        user: {
          email: "newpriest@test.com",
          first_name: "New",
          last_name: "Priest",
          phone: "1234567899",
          role: "priest",
          church_id: church.id
        }
      }
    end

    assert_equal church, User.last.church
  end

  test "should not assign church when role is not priest" do
    church = churches(:one)
    assert_difference("User.count") do
      post users_url, params: {
        user: {
          email: "newguardian@test.com",
          first_name: "New",
          last_name: "Guardian",
          phone: "1234567898",
          role: "guardian",
          church_id: church.id
        }
      }
    end

    assert_nil User.last.church_id
  end

  # ---------------------------------------------------------------------------
  # Impersonation
  # ---------------------------------------------------------------------------

  test "super_admin can impersonate another user" do
    sign_in users(:super_admin)
    post impersonate_user_path(users(:one))
    assert_redirected_to root_path
    assert_match users(:one).full_name, flash[:notice]
  end

  test "impersonation sets current session to the target user" do
    post impersonate_user_path(users(:admin_user))
    follow_redirect!
    # Confirm the impersonated user's name appears in the flash
    assert_match users(:admin_user).full_name, flash[:notice]
  end

  test "regular user cannot impersonate" do
    sign_in users(:one)
    post impersonate_user_path(users(:two))
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end

  test "admin (non-super-admin) cannot impersonate" do
    sign_in users(:admin_user)
    post impersonate_user_path(users(:one))
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end

  test "stop_impersonating ends the session and redirects to root" do
    sign_in users(:super_admin)
    post impersonate_user_path(users(:one))
    post stop_impersonating_path
    assert_redirected_to root_path
    assert_equal I18n.t("users.notices.stopped_impersonating"), flash[:notice]
  end

  test "after stop_impersonating the original user session is restored" do
    sign_in users(:super_admin)
    post impersonate_user_path(users(:one))
    post stop_impersonating_path
    # super_admin is back — can still access protected pages
    get users_url
    assert_response :success
  end

  test "stop_impersonating without active impersonation still redirects to root" do
    sign_in users(:super_admin)
    post stop_impersonating_path
    assert_redirected_to root_path
  end
end
