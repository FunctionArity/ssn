require "test_helper"

class CommentMentionTest < ActiveSupport::TestCase
  setup do
    comment = services(:one).comments.create!(user: users(:one), body: %(<p><a href="/users/#{users(:two).id}">@#{users(:two).full_name}</a></p>))
    @mention = comment.mentions.sole
  end

  test "read! marks it read and keeps the first time it was read" do
    travel_to 1.hour.ago do
      @mention.read!
    end
    first_read_at = @mention.read_at

    @mention.read!

    assert_not @mention.reload.unread?
    assert_equal first_read_at, @mention.read_at
  end

  test "unread! marks it unread again" do
    @mention.read!

    @mention.unread!

    assert @mention.reload.unread?
  end
end
