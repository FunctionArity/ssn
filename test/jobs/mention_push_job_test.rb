require "test_helper"

class MentionPushJobTest < ActiveJob::TestCase
  include WebPushTestHelper

  setup do
    @user = users(:vocal_guardian)
    @author = users(:one)
    @comment = services(:one).comments.create!(user: @author, body: <<~HTML)
      <p><a href="/users/#{@user.id}">@#{@user.full_name}</a> pasá a buscar</p><p>la llave</p>
    HTML
    @mention = @comment.mentions.sole
    @phone = @user.push_subscriptions.create!(endpoint: "https://web.push.apple.com/phone", p256dh_key: "a", auth_key: "b")
    @laptop = @user.push_subscriptions.create!(endpoint: "https://fcm.googleapis.com/fcm/send/laptop", p256dh_key: "c", auth_key: "d")
  end

  test "notifies every device of the mentioned user, linking to the comment" do
    capture_web_pushes do |sent|
      MentionPushJob.perform_now(@mention)

      assert_equal [ @phone.endpoint, @laptop.endpoint ].sort, sent.pluck(:endpoint).sort
      message = JSON.parse(sent.first[:message], symbolize_names: true)
      assert_equal "#{@author.full_name} te mencionó", message[:title]
      assert_equal "Servicio de #{services(:one).comment_subject}: @#{@user.full_name} pasá a buscar la llave", message[:options][:body]
      assert_equal "/services/#{services(:one).to_param}#comment_#{@comment.id}", message[:options][:data][:path]
      assert_equal "comment_#{@comment.id}", message[:options][:tag]
      assert_equal [ { action: "open", title: "Ver el comentario" } ], message[:options][:actions]
    end
  end

  test "doesn't notify about a comment already read" do
    @mention.read!

    capture_web_pushes do |sent|
      MentionPushJob.perform_now(@mention)
      assert_empty sent
    end
  end

  test "sends nothing without VAPID keys" do
    capture_web_pushes(vapid: false) do |sent|
      MentionPushJob.perform_now(@mention)
      assert_empty sent
    end
  end

  test "is dropped when the comment no longer mentions the user" do
    @comment.update!(body: "<p>sin menciones</p>")

    capture_web_pushes do |sent|
      assert_nothing_raised { perform_enqueued_jobs(only: MentionPushJob) }
      assert_empty sent
    end
  end
end
