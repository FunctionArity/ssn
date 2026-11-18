require "test_helper"

class PersonalAccessTokenTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "generates an API token for the user, keeping only its jti and last characters" do
    record = PersonalAccessToken.generate_for(@user)

    assert_equal @user, ApiToken.user_for(record.token)
    assert_equal record.token.last(6), record.hint
    assert_in_delta PersonalAccessToken::LIFETIME.from_now, record.expires_at, 1.second
    assert_nil PersonalAccessToken.find(record.id).token
  end

  test "the token works until it expires" do
    record = PersonalAccessToken.generate_for(@user)

    travel PersonalAccessToken::LIFETIME - 1.minute do
      assert_equal @user, ApiToken.user_for(record.token)
      assert_includes PersonalAccessToken.active, record
    end
    travel PersonalAccessToken::LIFETIME + 1.minute do
      assert_nil ApiToken.user_for(record.token)
      assert_not_includes PersonalAccessToken.active, record
      assert_includes PersonalAccessToken.expired, record
    end
  end

  test "revoking stops the token at once and forgets it" do
    record = PersonalAccessToken.generate_for(@user)

    record.revoke!

    assert_nil ApiToken.user_for(record.token)
    assert_not PersonalAccessToken.exists?(record.id)
    assert JwtDenylist.revoked?(record.jti)
  end
end
