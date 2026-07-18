require "test_helper"

class HeadquarterTest < ActiveSupport::TestCase
  def valid_attributes
    {
      country: "Argentina",
      state: "Mendoza",
      city: "Mendoza",
      address: "San Martín 1234",
      phone: "261 555 1234"
    }
  end

  test "valid with mandatory fields and one contact method" do
    assert Headquarter.new(valid_attributes).valid?
  end

  test "invalid without country, state, city and address" do
    headquarter = Headquarter.new(phone: "261 555 1234")
    assert_not headquarter.valid?
    assert headquarter.errors[:country].present?
    assert headquarter.errors[:state].present?
    assert headquarter.errors[:city].present?
    assert headquarter.errors[:address].present?
  end

  test "invalid without any contact method" do
    headquarter = Headquarter.new(valid_attributes.except(:phone))
    assert_not headquarter.valid?
    assert headquarter.errors[:base].present?
  end

  test "valid with only email as contact method" do
    headquarter = Headquarter.new(valid_attributes.except(:phone).merge(email: "ssu@example.com"))
    assert headquarter.valid?
  end

  test "valid with only whatsapp as contact method" do
    headquarter = Headquarter.new(valid_attributes.except(:phone).merge(whatsapp: "261 555 1234"))
    assert headquarter.valid?
  end
end
