require "test_helper"

class GuardTest < ActiveSupport::TestCase
  test "validates presence of day" do
    guard = Guard.new(day: nil, vocal: users(:one), priest: users(:two))
    guard.guardians << users(:one)

    assert_not guard.valid?
    assert guard.errors[:day].any?
  end

  test "validates that at least one guardian is selected" do
    guard = Guard.new(day: Date.today, vocal: users(:one), priest: users(:two))

    assert_not guard.valid?
    assert guard.errors[:guardians].any?
  end

  test "is valid with day and at least one guardian" do
    guard = Guard.new(day: Date.today, vocal: users(:one), priest: users(:two))
    guard.guardians << users(:one)

    assert guard.valid?
  end
end
