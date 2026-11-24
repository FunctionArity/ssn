require "test_helper"

# English is offered next to Spanish (?locale=en), so every text the app has in Spanish needs an English version.
class I18nTest < ActiveSupport::TestCase
  test "every Spanish translation of the app has an English one" do
    spanish_keys = Rails.root.glob("config/locales/*.yml").flat_map do |file|
      keys_in(YAML.load_file(file).fetch("es", {}))
    end

    missing = spanish_keys.reject { I18n.exists?(it, :en) }
    assert_empty missing, "Add these keys to config/locales/en.yml"
  end

  private

  def keys_in(hash, prefix = nil)
    hash.flat_map do |key, value|
      path = [ prefix, key ].compact.join(".")
      value.is_a?(Hash) ? keys_in(value, path) : [ path ]
    end
  end
end
