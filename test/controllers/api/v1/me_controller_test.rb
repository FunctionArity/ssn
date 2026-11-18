require "test_helper"

class Api::V1::MeControllerTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  test "needs a token" do
    get api_v1_me_url, as: :json

    assert_response :unauthorized
    assert_equal I18n.t("devise.failure.unauthenticated"), json["error"]
  end

  test "refuses a token it didn't sign" do
    get api_v1_me_url, headers: { "Authorization" => "Bearer not-a-token" }, as: :json

    assert_response :unauthorized
  end

  test "refuses an expired token" do
    headers = api_headers(users(:one))

    travel ApiToken::TTL + 1.minute do
      get api_v1_me_url, headers: headers, as: :json
    end

    assert_response :unauthorized
  end

  test "refuses tokens issued before the password changed" do
    headers = api_headers(users(:one))
    users(:one).update!(password: "a-new-password")

    get api_v1_me_url, headers: headers, as: :json

    assert_response :unauthorized
  end

  test "refuses the token of a user locked since" do
    headers = api_headers(users(:one))
    users(:one).lock_access!(send_instructions: false)

    get api_v1_me_url, headers: headers, as: :json

    assert_response :unauthorized
  end

  test "returns the user and their sede" do
    get api_v1_me_url, headers: api_headers(users(:one)), as: :json

    assert_response :success
    assert_nil json["token"]
    assert_equal "Rodriguez Pablo", json.dig("user", "full_name")
    assert_equal "vocal", json.dig("user", "role")
    assert_equal false, json.dig("user", "can_switch_headquarter")
    assert_equal "Mendoza", json.dig("headquarter", "city")
  end

  test "super admins work in the sede they send" do
    get api_v1_me_url, headers: api_headers(users(:super_admin), headquarter: headquarters(:two)), as: :json

    assert_equal true, json.dig("user", "can_switch_headquarter")
    assert_equal "Quito", json.dig("headquarter", "city")
  end

  test "other users stay in their own sede whatever they send" do
    get api_v1_me_url, headers: api_headers(users(:admin_user), headquarter: headquarters(:two)), as: :json

    assert_equal "Mendoza", json.dig("headquarter", "city")
  end
end
