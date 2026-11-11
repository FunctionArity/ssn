require "test_helper"

class GoogleIdTokenTest < ActiveSupport::TestCase
  include GoogleIdTokenTestHelper

  test "a token Google signed for this app gives its claims" do
    with_google_keys do
      claims = GoogleIdToken.verify(google_id_token(email: "ana@example.test"))

      assert_equal "ana@example.test", claims["email"]
      assert claims["email_verified"]
    end
  end

  test "accepts both of Google's issuer names" do
    with_google_keys do
      assert GoogleIdToken.verify(google_id_token(iss: "accounts.google.com"))
    end
  end

  test "rejects tokens for another app, from another issuer, expired or signed with another key" do
    other_key = JWT::JWK.new(OpenSSL::PKey::RSA.generate(2048), kid: "test-key")

    with_google_keys do
      assert_nil GoogleIdToken.verify(google_id_token(aud: "another-app.apps.googleusercontent.com"))
      assert_nil GoogleIdToken.verify(google_id_token(iss: "https://evil.example.test"))
      assert_nil GoogleIdToken.verify(google_id_token(exp: 1.minute.ago.to_i))
      assert_nil GoogleIdToken.verify(google_id_token(key: other_key))
      assert_nil GoogleIdToken.verify("not-a-token")
      assert_nil GoogleIdToken.verify(nil)
    end
  end

  test "rejects unsigned tokens" do
    with_google_keys do
      unsigned = JWT.encode({ iss: "https://accounts.google.com", aud: GOOGLE_CLIENT_ID, email: "x@example.test", exp: 1.hour.from_now.to_i }, nil, "none")

      assert_nil GoogleIdToken.verify(unsigned)
    end
  end
end
