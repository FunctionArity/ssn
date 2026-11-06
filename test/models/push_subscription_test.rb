require "test_helper"

class PushSubscriptionTest < ActiveSupport::TestCase
  include WebPushTestHelper

  def build(endpoint)
    users(:one).push_subscriptions.build(endpoint: endpoint, p256dh_key: "p256dh", auth_key: "auth")
  end

  test "accepts the endpoints of the browsers' push services" do
    %w[
      https://fcm.googleapis.com/fcm/send/abc
      https://updates.push.services.mozilla.com/wpush/v2/abc
      https://web.push.apple.com/abc
      https://wns2-bl2p.notify.windows.com/w/?token=abc
    ].each { |endpoint| assert build(endpoint).valid?, endpoint }
  end

  test "rejects endpoints anywhere else, since the server posts to them" do
    [
      "http://fcm.googleapis.com/fcm/send/abc",
      "https://evilfcm.googleapis.com.example.com/abc",
      "https://169.254.169.254/latest/meta-data",
      "https://localhost/push",
      "not a url",
      "https://exa mple.com"
    ].each { |endpoint| assert build(endpoint).invalid?, endpoint }
  end

  test "deliver sends the message to the endpoint, encrypted with its keys" do
    subscription = build("https://fcm.googleapis.com/fcm/send/abc").tap(&:save!)

    capture_web_pushes do |sent|
      subscription.deliver(title: "Hola", options: { body: "Texto" })

      assert_equal 1, sent.size
      assert_equal({ title: "Hola", options: { body: "Texto" } }.to_json, sent.first[:message])
      assert_equal [ "https://fcm.googleapis.com/fcm/send/abc", "p256dh", "auth" ], sent.first.values_at(:endpoint, :p256dh, :auth)
      assert_equal PushSubscription.vapid, sent.first[:vapid]
    end
  end

  test "deliver deletes a subscription the push service no longer knows" do
    subscription = build("https://fcm.googleapis.com/fcm/send/abc").tap(&:save!)
    expired = WebPush::ExpiredSubscription.new(Struct.new(:body).new(""), "fcm.googleapis.com")

    capture_web_pushes(raising: expired) { subscription.deliver(title: "Hola") }

    assert_not PushSubscription.exists?(subscription.id)
  end

  test "other push service errors are raised, so the job retries or reports them" do
    subscription = build("https://fcm.googleapis.com/fcm/send/abc").tap(&:save!)
    error = WebPush::PushServiceError.new(Struct.new(:body).new(""), "fcm.googleapis.com")

    capture_web_pushes(raising: error) do
      assert_raises(WebPush::PushServiceError) { subscription.deliver(title: "Hola") }
    end
    assert PushSubscription.exists?(subscription.id)
  end
end
