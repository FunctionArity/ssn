require "test_helper"

class CommentMailerTest < ActionMailer::TestCase
  test "mention sends the comment with mentions as plain text and a link to it" do
    service = services(:one)
    author = users(:one)
    recipient = users(:vocal_guardian)
    comment = service.comments.create!(user: author, body: %(<p><a href="/users/#{recipient.id}">@#{recipient.full_name}</a> llamar</p>))

    email = CommentMailer.with(comment: comment, user: recipient).mention

    assert_equal [ recipient.email ], email.to
    assert_equal I18n.t("comment_mailer.mention.service.subject", name: service.full_name), email.subject
    assert_includes email.body.to_s, author.full_name
    assert_includes email.body.to_s, "<strong>@#{recipient.full_name}</strong> llamar"
    assert_includes email.body.to_s, "http://example.com/services/#{service.id}#comment_#{comment.id}"
  end
end
