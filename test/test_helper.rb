require "simplecov"
SimpleCov.start "rails" do
  add_filter "/jobs/"
  add_filter "/mailers/"
end

unless ENV["RM_INFO"]
  require "minitest/reporters"
  Minitest::Reporters.use! Minitest::Reporters::ProgressReporter.new
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    parallelize_setup { |worker| SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}" }
    parallelize_teardown { |_worker| SimpleCov.result }

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Records made by the tests belong to the Mendoza sede, like the fixtures; requests use the signed-in user's sede.
    setup { ActsAsTenant.test_tenant = headquarters(:one) }
    teardown { ActsAsTenant.test_tenant = nil }
  end
end

# Google ID tokens signed with a throwaway key, which GoogleIdToken trusts as Google's while the block runs.
module GoogleIdTokenTestHelper
  GOOGLE_CLIENT_ID = "test-client.apps.googleusercontent.com".freeze

  def with_google_keys(&)
    keys = JWT::JWK::Set.new(google_signing_key).export
    GoogleIdToken.stub(:client_id, GOOGLE_CLIENT_ID) do
      GoogleIdToken.stub(:jwks, ->(_options = {}) { keys }, &)
    end
  end

  # A token like the one One Tap gives the page; claims override the defaults.
  def google_id_token(key: google_signing_key, **claims)
    payload = { iss: "https://accounts.google.com", aud: GOOGLE_CLIENT_ID, sub: "123",
                email: "pablo@rodriguez.com", email_verified: true, iat: Time.now.to_i, exp: 1.hour.from_now.to_i }
    JWT.encode(payload.merge(claims), key.signing_key, "RS256", kid: key[:kid])
  end

  def google_signing_key
    @google_signing_key ||= JWT::JWK.new(OpenSSL::PKey::RSA.generate(2048), kid: "test-key")
  end
end

# Web Push with throwaway VAPID keys, collecting what would be sent instead of calling the push services.
module WebPushTestHelper
  # vapid: false is a server without VAPID keys, where push notifications are off.
  def capture_web_pushes(raising: nil, vapid: true)
    sent = []
    keys = WebPush.generate_key
    vapid = { subject: "mailto:test@example.test", public_key: (keys.public_key if vapid), private_key: (keys.private_key if vapid) }

    PushSubscription.stub(:vapid, vapid) do
      WebPush.stub(:payload_send, ->(**args) { sent << args; raise raising if raising }) { yield sent }
    end
  end
end
