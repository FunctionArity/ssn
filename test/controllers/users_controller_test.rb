require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
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

  test "should create user" do
    assert_difference("User.count") do
      post users_url, params: { user: { email: Faker::Internet.email, first_name: @user.first_name, last_name: @user.last_name, phone: @user.phone } }
    end

    assert_redirected_to user_url(User.last)
  end

  test "should create user without password using auto-generated one" do
    assert_difference("User.count") do
      post users_url, params: { user: { email: Faker::Internet.email, first_name: "Auto", last_name: "Pass", phone: "1111111111", password: "" } }
    end

    assert_redirected_to user_url(User.last)
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
end
