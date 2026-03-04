require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  include Warden::Test::Helpers

  setup do
    @user = users(:one)
    login_as(@user, scope: :user)
  end

  teardown do
    Warden.test_reset!
  end

  test "visiting the index" do
    visit users_url
    assert_selector "h1", text: I18n.t("users.index.title")
  end

  test "should create user" do
    visit users_url
    click_on I18n.t("users.index.new_user")

    fill_in User.human_attribute_name(:first_name), with: @user.first_name
    fill_in User.human_attribute_name(:last_name), with: @user.last_name
    fill_in User.human_attribute_name(:email), with: Faker::Internet.email
    fill_in User.human_attribute_name(:phone), with: "1234567899"
    click_on I18n.t("helpers.submit.create", model: User.model_name.human)

    assert_text I18n.t("users.notices.created")
    click_on I18n.t("users.show.back")
  end

  test "should update User" do
    visit user_url(@user)
    click_on I18n.t("edit"), match: :first

    fill_in User.human_attribute_name(:email), with: Faker::Internet.email
    fill_in User.human_attribute_name(:first_name), with: @user.first_name
    fill_in User.human_attribute_name(:last_name), with: @user.last_name
    click_on I18n.t("helpers.submit.update", model: User.model_name.human)

    assert_text I18n.t("users.notices.updated")
    click_on I18n.t("users.show.back")
  end

  test "should destroy User" do
    visit user_url(users(:agustin))
    click_on I18n.t("destroy"), match: :first
    click_on "Aceptar"

    assert_text I18n.t("users.notices.destroyed")
  end
end
