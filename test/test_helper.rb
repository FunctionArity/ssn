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

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    parallelize_setup { |worker| SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}" }
    parallelize_teardown { |_worker| SimpleCov.result }

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

# Web Push with throwaway VAPID keys, collecting what would be sent instead of calling the push services.
module WebPushTestHelper
  # vapid: false is a server without VAPID keys, where push notifications are off.
  def capture_web_pushes(raising: nil, vapid: true)
    sent = []
    keys = WebPush.generate_key
    vapid = { subject: "mailto:test@example.test", public_key: (keys.public_key if vapid), private_key: (keys.private_key if vapid) }

    replacing(PushSubscription, :vapid, -> { vapid }) do
      replacing(WebPush, :payload_send, ->(**args) { sent << args; raise raising if raising }) { yield sent }
    end
  end

  private

  def replacing(object, name, implementation)
    original = object.method(name)
    object.define_singleton_method(name, implementation)
    yield
  ensure
    object.define_singleton_method(name, original)
  end
end
