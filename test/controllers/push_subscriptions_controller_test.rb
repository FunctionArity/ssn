require "test_helper"

class PushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  ENDPOINT = "https://fcm.googleapis.com/fcm/send/abc".freeze

  setup do
    @user = users(:vocal_guardian)
    sign_in @user
  end

  def subscribe(endpoint: ENDPOINT, p256dh: "p256dh", auth: "auth")
    post push_subscription_path, as: :json,
      params: { push_subscription: { endpoint: endpoint, expirationTime: nil, keys: { p256dh: p256dh, auth: auth } } },
      headers: { "User-Agent" => "Phone" }
  end

  test "saves the device of the current user" do
    assert_difference -> { @user.push_subscriptions.count } do
      subscribe
    end

    assert_response :no_content
    subscription = @user.push_subscriptions.sole
    assert_equal [ ENDPOINT, "p256dh", "auth", "Phone" ], [ subscription.endpoint, subscription.p256dh_key, subscription.auth_key, subscription.user_agent ]
  end

  test "saving it again updates it, and moves it to whoever is signed in on that device now" do
    users(:one).push_subscriptions.create!(endpoint: ENDPOINT, p256dh_key: "old", auth_key: "old")

    assert_no_difference -> { PushSubscription.count } do
      subscribe(p256dh: "new")
    end

    subscription = PushSubscription.find_by!(endpoint: ENDPOINT)
    assert_equal [ @user, "new" ], [ subscription.user, subscription.p256dh_key ]
  end

  test "rejects endpoints outside the browsers' push services" do
    assert_no_difference -> { PushSubscription.count } do
      subscribe(endpoint: "https://169.254.169.254/latest/meta-data")
    end

    assert_response :unprocessable_entity
  end

  test "forgets the device, only for the current user" do
    @user.push_subscriptions.create!(endpoint: ENDPOINT, p256dh_key: "a", auth_key: "b")
    other = users(:one).push_subscriptions.create!(endpoint: "https://fcm.googleapis.com/fcm/send/other", p256dh_key: "a", auth_key: "b")

    delete push_subscription_path, as: :json, params: { endpoint: ENDPOINT }
    delete push_subscription_path, as: :json, params: { endpoint: other.endpoint }

    assert_response :no_content
    assert_not @user.push_subscriptions.exists?
    assert PushSubscription.exists?(other.id)
  end

  test "an admin impersonating someone can't get their notifications" do
    sign_in users(:super_admin)
    post impersonate_user_path(@user)

    assert_no_difference -> { PushSubscription.count } do
      subscribe
    end

    assert_response :forbidden
  end

  test "requires signing in" do
    sign_out @user

    subscribe

    assert_response :unauthorized
  end
end
