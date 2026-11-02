require "test_helper"

class ServiceMailerTest < ActionMailer::TestCase
  setup do
    @service = services(:one)
    @recipient = users(:vocal_guardian)
    @author = users(:one)
  end

  def mention_email
    ServiceMailer.with(service: @service, user: @recipient, author: @author).mention
  end

  test "mention goes to the mentioned user from the app sender, with a link to the service" do
    @service.update!(comments: "<p>Llamar antes</p>")

    email = mention_email

    assert_equal [ @recipient.email ], email.to
    assert_equal [ "no-reply@serviciosacerdotalnocturno.org" ], email.from
    assert_includes email.subject, @service.full_name
    assert_includes email.body.to_s, @author.full_name
    assert_includes email.body.to_s, "<p>Llamar antes</p>"
    assert_includes email.body.to_s, "http://example.com/services/#{@service.id}"
  end

  test "mention shows mentions as bold text instead of relative links" do
    @service.update!(comments: %(<p><a href="/users/#{@recipient.id}">@#{@recipient.full_name}</a> ver <a href="https://example.com/x">info</a></p>))

    body = mention_email.body.to_s

    assert_includes body, "<strong>@#{@recipient.full_name}</strong>"
    assert_not_includes body, %(href="/users/)
    assert_includes body, %(<a href="https://example.com/x">info</a>)
  end

  test "mention sanitizes the comment" do
    @service.update!(comments: %(<p onclick="alert(1)">ok</p><script>alert(2)</script><a href="javascript:alert(3)">x</a><img src="x" onerror="alert(4)">))

    body = mention_email.body.to_s

    assert_not_includes body, "<script"
    assert_not_includes body, "onclick"
    assert_not_includes body, "onerror"
    assert_not_includes body, "javascript:"
  end

  test "mention escapes the names of the service and the author" do
    @service.update!(full_name: "<b>Juan</b>", comments: "<p>ok</p>")
    @author.update_column(:first_name, "<i>Ana</i>")

    email = mention_email

    assert_includes email.body.to_s, "&lt;b&gt;Juan&lt;/b&gt;"
    assert_includes email.body.to_s, "&lt;i&gt;Ana&lt;/i&gt;"
    assert_includes email.subject, "<b>Juan</b>"
  end

  test "mention keeps the line breaks of plain text comments" do
    @service.update!(comments: "Primera línea\nSegunda & línea")

    assert_includes mention_email.body.to_s, "Primera línea\n<br />Segunda &amp; línea"
  end
end
