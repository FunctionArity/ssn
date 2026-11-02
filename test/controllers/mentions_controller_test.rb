require "test_helper"

class MentionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:vocal_guardian)
    @comment = services(:one).comments.create!(user: users(:one), body: %(<p><a href="/users/#{@user.id}">@#{@user.full_name}</a> llamar</p>))
    sign_in @user
  end

  test "the top nav shows the number of unread comments" do
    get services_url

    assert_select "a#mentions_indicator[href=?]", mentions_path do
      assert_select "span", text: "1"
    end
  end

  test "the top nav shows no number without unread comments" do
    @comment.mentions.sole.read!

    get services_url

    assert_select "a#mentions_indicator span", count: 0
  end

  test "index lists the comments that mention the user, linking to the comment" do
    services(:completed_one).comments.create!(user: users(:one), body: "<p>sin mención</p>")

    get mentions_url

    assert_response :success
    assert_select "ul > li", count: 1
    assert_select "a[href=?]", service_path(services(:one), anchor: "comment_#{@comment.id}")
    assert_select "button", text: I18n.t("mentions.index.read_all")
  end

  test "read_all marks every mention of the user as read" do
    other = users(:unrelated_vocal)
    services(:completed_one).comments.create!(user: users(:one), body: %(<p><a href="/users/#{other.id}">@x</a></p>))

    post read_all_mentions_url

    assert_redirected_to mentions_url
    assert_equal 0, @user.comment_mentions.unread.count
    assert_equal 1, other.comment_mentions.unread.count
  end
end
