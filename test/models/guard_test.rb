require "test_helper"

class GuardTest < ActiveSupport::TestCase
  test "validates presence of day_number" do
    guard = Guard.new(day_number: nil, vocal: users(:one), priest: users(:two))
    guard.guardians << users(:one)

    assert_not guard.valid?
    assert guard.errors[:day_number].any?
  end

  test "validates that at least one guardian is selected" do
    guard = Guard.new(day_number: 1, vocal: users(:one), priest: users(:two))

    assert_not guard.valid?
    assert guard.errors[:guardians].any?
  end

  test "is valid with day_number and at least one guardian" do
    guard = Guard.new(day_number: 1, due_date: Date.today, vocal: users(:one), priest: users(:two), guard_setup: guard_setups(:one))
    guard.guardians << users(:one)

    assert guard.valid?
  end
end
