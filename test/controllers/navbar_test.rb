require "test_helper"

class NavbarTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "shows the user's picture" do
    user = users(:one)
    user.avatar.attach(io: StringIO.new("fake image"), filename: "avatar.png", content_type: "image/png")
    sign_in user

    get guards_url

    assert_select "nav [data-controller=avatar-fallback]" do
      assert_select "img#navbar_avatar"
      assert_select "[data-avatar-fallback-target=placeholder] i.#{user.role_icon_class}"
    end
  end

  test "shows the role icon to users without a picture" do
    sign_in users(:one)

    get guards_url

    assert_select "#navbar_avatar", count: 0
    assert_select "nav i.#{users(:one).role_icon_class}"
  end

  test "the navbar doesn't show the sede" do
    sign_in users(:super_admin)

    get guards_url

    assert_select "nav #navbar_headquarter", count: 0
  end

  test "admins and super admins have a ring of their own around their picture" do
    { regular: nil, admin: "ring-sky-500", super_admin: "ring-amber-500" }.each do |user_type, ring|
      user = users(:one)
      user.update_columns(user_type: User.user_types[user_type])
      sign_in user

      get guards_url

      assert_select "nav i.ph-crown, nav i.ph-crown-simple", count: 0
      assert_select "#navbar_user_picture" do |picture|
        rings = picture.first["class"].split.grep(/\Aring-(sky|amber)/)
        assert_equal Array(ring), rings, "#{user_type} ring"
      end
    end
  end
end
