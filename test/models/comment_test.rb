require "test_helper"

class CommentTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @service = services(:one)
    @author = users(:one)
  end

  test "mentioned users get it unread and by email, each once" do
    mentioned = users(:vocal_guardian)

    comment = nil
    assert_enqueued_emails(1) do
      comment = @service.comments.create!(user: @author, body: "<p>#{mention_link(mentioned)} y #{mention_link(mentioned)}</p>")
    end

    assert_equal [ mentioned ], comment.mentions.map(&:user)
    assert comment.mentions.sole.unread?
    assert_enqueued_email_with CommentMailer, :mention, params: { comment: comment, user: mentioned }
  end

  test "skips the author, locked and invited users, and links that aren't mentions" do
    users(:vocal_guardian).update_column(:locked_at, Time.current)
    users(:unrelated_vocal).update_column(:invitation_token, "pending")

    assert_no_enqueued_emails do
      comment = @service.comments.create!(user: @author, body: <<~HTML)
        <p>#{mention_link(@author)} #{mention_link(users(:vocal_guardian))} #{mention_link(users(:unrelated_vocal))}
        <a href="https://example.com/users/#{users(:two).id}">x</a> <a href="/users/#{users(:two).id}/edit">y</a> <a href="/users/0">z</a></p>
      HTML
      assert_empty comment.mentions
    end
  end

  test "keeps a comment that only has a mention" do
    body = "<p>#{mention_link(users(:two))}</p>"

    assert_equal body, @service.comments.create!(user: @author, body: body).body
  end

  test "allows up to MAX_LENGTH characters of visible text, not counting the markup" do
    at_limit = "<p><strong>#{"a" * (Comment::MAX_LENGTH - 1)}&amp;</strong></p>"
    assert @service.comments.build(user: @author, body: at_limit).valid?

    too_long = @service.comments.build(user: @author, body: "<p>#{"a" * (Comment::MAX_LENGTH + 1)}</p>")
    assert_not too_long.valid?
    assert too_long.errors.added?(:body, :too_long, count: Comment::MAX_LENGTH)
  end

  test "is invalid with only empty rich text markup" do
    [ "<p><br></p>", "<h2><br></h2>", "<p> &nbsp; </p>", "" ].each do |empty|
      comment = @service.comments.build(user: @author, body: empty)
      assert_not comment.valid?, "expected #{empty.inspect} to be blank"
      assert comment.errors.added?(:body, :blank)
    end
  end

  test "a reply starts mentioning the author and the others mentioned, but not the replier" do
    replier = users(:two)
    other = users(:vocal_guardian)
    comment = @service.comments.create!(user: @author, body: "<p>#{mention_link(replier)} #{mention_link(other)} #{mention_link(other)} hola</p>")

    assert_equal "<p>#{mention_link(@author)} #{mention_link(other)}&nbsp;</p>", comment.reply_body_for(replier)
  end

  private

  def mention_link(user)
    %(<a href="/users/#{user.id}">@#{user.full_name}</a>)
  end
end
