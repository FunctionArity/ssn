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

  test "due date is this month's day of the setup" do
    travel_to Date.new(2027, 1, 10) do
      assert_equal Date.new(2027, 1, 31), GuardSetup.new(day_number: 31).due_date
      assert_equal Date.new(2027, 1, 5), GuardSetup.new(day_number: 5).due_date
    end
  end

  test "due date is the month's last day when the month doesn't have the setup's day" do
    travel_to Date.new(2027, 2, 10) do
      (28..31).each { |day| assert_equal Date.new(2027, 2, 28), GuardSetup.new(day_number: day).due_date, "day #{day}" }
    end

    travel_to Date.new(2028, 2, 10) do
      assert_equal Date.new(2028, 2, 29), GuardSetup.new(day_number: 31).due_date
    end

    travel_to Date.new(2027, 4, 10) do
      assert_equal Date.new(2027, 4, 30), GuardSetup.new(day_number: 31).due_date
    end
  end
end
