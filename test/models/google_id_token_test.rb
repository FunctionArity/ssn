require "test_helper"

class GoogleIdTokenTest < ActiveSupport::TestCase
  include GoogleIdTokenTestHelper

  # Google's keys are cached, and the test environment's cache stores nothing.
  setup do
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown { Rails.cache = @original_cache }

  # CI can't read the real credentials, so the test brings its own.
  test "the client id is the app's Google client from the credentials" do
    credentials = { google: { client_id: GOOGLE_CLIENT_ID } }

    Rails.application.stub(:credentials, credentials) do
      assert_equal GOOGLE_CLIENT_ID, GoogleIdToken.client_id
    end
  end

  test "there's no client id without Google credentials" do
    Rails.application.stub(:credentials, {}) { assert_nil GoogleIdToken.client_id }
  end

  # verify

  test "returns the claims of a token Google signed for this app" do
    claims = with_google_keys { GoogleIdToken.verify(google_id_token(email: "ana@example.test")) }

    assert_equal "ana@example.test", claims["email"]
    assert_equal true, claims["email_verified"]
  end

  test "accepts both of Google's issuers" do
    with_google_keys do
      assert GoogleIdToken.verify(google_id_token(iss: "accounts.google.com"))
      assert GoogleIdToken.verify(google_id_token(iss: "https://accounts.google.com"))
    end
  end

  test "rejects a missing token" do
    with_google_keys do
      assert_nil GoogleIdToken.verify(nil)
      assert_nil GoogleIdToken.verify("")
    end
  end

  test "rejects every token when the app has no Google client" do
    token = with_google_keys { google_id_token }

    GoogleIdToken.stub(:client_id, nil) { assert_nil GoogleIdToken.verify(token) }
  end

  test "rejects tokens that aren't Google's for this app, still valid" do
    another_key = JWT::JWK.new(OpenSSL::PKey::RSA.generate(2048), kid: "another-key")

    with_google_keys do
      assert_nil GoogleIdToken.verify(google_id_token(aud: "another-app.apps.googleusercontent.com")), "another app's"
      assert_nil GoogleIdToken.verify(google_id_token(iss: "https://evil.example.test")), "another issuer's"
      assert_nil GoogleIdToken.verify(google_id_token(exp: 1.minute.ago.to_i)), "expired"
      assert_nil GoogleIdToken.verify(google_id_token(key: another_key)), "signed with a key Google doesn't have"
      assert_nil GoogleIdToken.verify("not.a.token"), "garbage"
    end
  end

  test "rejects a token that isn't signed with RS256" do
    payload = { iss: "https://accounts.google.com", aud: GOOGLE_CLIENT_ID, email: "ana@example.test", exp: 1.hour.from_now.to_i }
    token = JWT.encode(payload, "shared-secret", "HS256")

    with_google_keys { assert_nil GoogleIdToken.verify(token) }
  end

  test "verifies tokens with the keys fetched from Google" do
    keys = JWT::JWK::Set.new(google_signing_key).export.to_json

    claims = GoogleIdToken.stub(:client_id, GOOGLE_CLIENT_ID) do
      with_google_certs(keys) { GoogleIdToken.verify(google_id_token(email: "ana@example.test")) }
    end

    assert_equal "ana@example.test", claims["email"]
  end

  # jwks

  test "fetches Google's keys once and then uses the cached ones" do
    with_google_certs({ keys: [ { kid: "a" } ] }.to_json) do
      2.times { assert_equal [ { "kid" => "a" } ], GoogleIdToken.jwks["keys"] }
    end

    assert_equal 1, @google_requests.size
    host, port, options = @google_requests.first
    assert_equal [ "www.googleapis.com", 443 ], [ host, port ]
    assert options[:use_ssl]
  end

  test "a token signed with a key it doesn't have fetches the keys again, at most every 5 minutes" do
    with_google_certs({ keys: [] }.to_json) do
      GoogleIdToken.jwks
      GoogleIdToken.jwks(kid_not_found: true)
      assert_equal 1, @google_requests.size, "fetched less than 5 minutes ago"

      travel 6.minutes do
        GoogleIdToken.jwks(kid_not_found: true)
        GoogleIdToken.jwks(kid_not_found: true)
      end
    end

    assert_equal 2, @google_requests.size
  end

  test "keeps the cached keys when Google can't be reached" do
    with_google_certs({ keys: [ { kid: "a" } ] }.to_json) { GoogleIdToken.jwks }

    keys = travel(6.minutes) do
      with_google_certs(raising: SocketError.new("getaddrinfo failed")) { GoogleIdToken.jwks(kid_not_found: true) }
    end

    assert_equal [ { "kid" => "a" } ], keys["keys"]
  end

  test "has no keys when Google can't be reached and none are cached" do
    warnings = []

    Rails.logger.stub(:warn, ->(message) { warnings << message }) do
      [ Timeout::Error.new, Errno::ECONNREFUSED.new ].each do |error|
        with_google_certs(raising: error) { assert_equal [], GoogleIdToken.jwks }
      end
      with_google_certs("<html>Bad gateway</html>") { assert_equal [], GoogleIdToken.jwks }
    end

    assert_equal 3, warnings.size
    assert warnings.all? { |warning| warning.start_with?("GoogleIdToken: failed to fetch Google's JWKS") }
  end

  private

  # Answers the requests for Google's keys with the given body, or raises the given error, instead of calling Google.
  # Returns what the block returns; the requests made, as [host, port, options], go in @google_requests.
  def with_google_certs(body = nil, raising: nil, &)
    requests = @google_requests = []
    http = Struct.new(:body) { def get(_uri) = Struct.new(:body).new(body) }.new(body)

    fake_start = lambda do |host, port, **options, &block|
      requests << [ host, port, options ]
      raise raising if raising

      block.call(http)
    end

    Net::HTTP.stub(:start, fake_start, &)
  end
end
