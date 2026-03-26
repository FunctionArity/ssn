require "test_helper"

class HealthFacilityTest < ActiveSupport::TestCase
  test "is valid with name and address" do
    facility = HealthFacility.new(name: "Hospital Central", address: "Alem y Salta, Mendoza", headquarter: headquarters(:one))
    assert facility.valid?
  end

  test "is invalid without name" do
    facility = HealthFacility.new(name: nil, address: "Alem y Salta, Mendoza")
    assert_not facility.valid?
    assert facility.errors[:name].any?
  end

  test "is invalid without address" do
    facility = HealthFacility.new(name: "Hospital Central", address: nil)
    assert_not facility.valid?
    assert facility.errors[:address].any?
  end

  test "is invalid without name and address" do
    facility = HealthFacility.new
    assert_not facility.valid?
    assert facility.errors[:name].any?
    assert facility.errors[:address].any?
  end
end
