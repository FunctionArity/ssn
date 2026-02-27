require "test_helper"

class GuardSetupTest < ActiveSupport::TestCase
  test "validates presence of day_number" do
    guard_setup = GuardSetup.new(day_number: nil, vocal: users(:one))
    guard_setup.guardians << users(:one)

    assert_not guard_setup.valid?
    assert guard_setup.errors[:day_number].any?
  end

  test "validates that at least one guardian is selected" do
    guard_setup = GuardSetup.new(day_number: 1, vocal: users(:one))

    assert_not guard_setup.valid?
    assert guard_setup.errors[:guardians].any?
  end

  test "is valid with day_number and at least one guardian" do
    guard_setup = GuardSetup.new(day_number: 1, vocal: users(:one))
    guard_setup.guardians << users(:one)

    assert guard_setup.valid?
  end
end
