require "test_helper"

class PriestSetupTest < ActiveSupport::TestCase
  test "is valid with valid attributes" do
    priest_setup = PriestSetup.new(priest: users(:priest_one), week_number: 3, day_of_week: 5)
    assert priest_setup.valid?
  end

  test "validates presence of week_number" do
    priest_setup = PriestSetup.new(priest: users(:priest_one), week_number: nil, day_of_week: 0)
    assert_not priest_setup.valid?
    assert priest_setup.errors[:week_number].any?
  end

  test "validates presence of day_of_week" do
    priest_setup = PriestSetup.new(priest: users(:priest_one), week_number: 1, day_of_week: nil)
    assert_not priest_setup.valid?
    assert priest_setup.errors[:day_of_week].any?
  end

  test "validates week_number is between 1 and 4" do
    [ 0, 5 ].each do |invalid|
      priest_setup = PriestSetup.new(priest: users(:priest_one), week_number: invalid, day_of_week: 1)
      assert_not priest_setup.valid?, "Expected week_number #{invalid} to be invalid"
      assert priest_setup.errors[:week_number].any?
    end
  end

  test "validates day_of_week is between 0 and 6" do
    [ -1, 7 ].each do |invalid|
      priest_setup = PriestSetup.new(priest: users(:priest_one), week_number: 1, day_of_week: invalid)
      assert_not priest_setup.valid?, "Expected day_of_week #{invalid} to be invalid"
      assert priest_setup.errors[:day_of_week].any?
    end
  end

  test "validates uniqueness of week_number scoped to day_of_week" do
    existing = priest_setups(:one)
    duplicate = PriestSetup.new(priest: users(:priest_two), week_number: existing.week_number, day_of_week: existing.day_of_week)
    assert_not duplicate.valid?
    assert duplicate.errors[:week_number].any?
  end

  test "allows same week_number with different day_of_week" do
    existing = priest_setups(:one)
    priest_setup = PriestSetup.new(priest: users(:priest_two), week_number: existing.week_number, day_of_week: existing.day_of_week + 1)
    assert priest_setup.valid?
  end

  test "description returns correct human-readable string" do
    priest_setup = PriestSetup.new(week_number: 1, day_of_week: 1)
    assert_equal "First Monday", priest_setup.description
  end

  test "description returns correct string for last week and day" do
    priest_setup = PriestSetup.new(week_number: 4, day_of_week: 6)
    assert_equal "Fourth Saturday", priest_setup.description
  end
end
