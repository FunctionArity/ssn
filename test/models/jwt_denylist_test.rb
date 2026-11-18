require "test_helper"

class JwtDenylistTest < ActiveSupport::TestCase
  test "revoking a token twice keeps one entry" do
    JwtDenylist.revoke("jti-1", 1.hour.from_now)
    JwtDenylist.revoke("jti-1", 1.hour.from_now)

    assert JwtDenylist.revoked?("jti-1")
    assert_not JwtDenylist.revoked?("jti-2")
    assert_equal 1, JwtDenylist.where(jti: "jti-1").count
  end

  test "the entries of tokens that have expired anyway can go" do
    JwtDenylist.revoke("old", 1.minute.ago)
    JwtDenylist.revoke("current", 1.minute.from_now)

    JwtDenylist.expired.delete_all

    assert_equal %w[current], JwtDenylist.pluck(:jti)
  end
end
