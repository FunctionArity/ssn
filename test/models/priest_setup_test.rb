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

  test "validates week_number is between 1 and 6" do
    [ 0, 7 ].each do |invalid|
      priest_setup = PriestSetup.new(priest: users(:priest_one), week_number: invalid, day_of_week: 1)
      assert_not priest_setup.valid?, "Expected week_number #{invalid} to be invalid"
      assert priest_setup.errors[:week_number].any?
    end
  end

  test "validates day_of_week is between 0 and 6" do
    [ -1, 8 ].each do |invalid|
      priest_setup = PriestSetup.new(priest: users(:priest_one), week_number: 1, day_of_week: invalid)
      assert_not priest_setup.valid?, "Expected day_of_week #{invalid} to be invalid"
      assert priest_setup.errors[:day_of_week].any?
    end
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

  # ─── day_of_current_month ────────────────────────────────────────────────────
  #
  # April 2026: starts on Wednesday (cwday=3). End of month: Thursday April 30.
  #   First occurrences: Mon=6, Tue=7, Wed=1, Thu=2, Fri=3, Sat=4, Sun=5
  #
  # March 2026: starts on Sunday (cwday=7). End of month: Tuesday March 31.
  #   First occurrences: Mon=2, Tue=3, Wed=4, Thu=5, Fri=6, Sat=7, Sun=1

  # Week 1 — first occurrence of each weekday in the month

  test "day_of_current_month week 1 Wednesday returns 1 when month starts on Wednesday" do
    setup = PriestSetup.new(week_number: 1, day_of_week: 3)
    assert_equal 1, setup.day_of_current_month(Date.new(2026, 4, 1))
  end

  test "day_of_current_month week 1 Monday returns first Monday" do
    setup = PriestSetup.new(week_number: 1, day_of_week: 1)
    assert_equal 6, setup.day_of_current_month(Date.new(2026, 4, 1))
  end

  test "day_of_current_month week 1 Sunday returns first Sunday" do
    setup = PriestSetup.new(week_number: 1, day_of_week: 7)
    assert_equal 5, setup.day_of_current_month(Date.new(2026, 4, 1))
  end

  test "day_of_current_month week 1 Sunday returns 1 when month starts on Sunday" do
    setup = PriestSetup.new(week_number: 1, day_of_week: 7)
    assert_equal 1, setup.day_of_current_month(Date.new(2026, 3, 1))
  end

  test "day_of_current_month week 1 Monday returns first Monday in March" do
    setup = PriestSetup.new(week_number: 1, day_of_week: 1)
    assert_equal 2, setup.day_of_current_month(Date.new(2026, 3, 1))
  end

  # Week 2 — second occurrence

  test "day_of_current_month week 2 Wednesday returns second Wednesday" do
    setup = PriestSetup.new(week_number: 2, day_of_week: 3)
    assert_equal 8, setup.day_of_current_month(Date.new(2026, 4, 1))
  end

  test "day_of_current_month week 2 Monday returns second Monday" do
    setup = PriestSetup.new(week_number: 2, day_of_week: 1)
    assert_equal 13, setup.day_of_current_month(Date.new(2026, 4, 1))
  end

  test "day_of_current_month week 2 Wednesday returns second Wednesday in March" do
    setup = PriestSetup.new(week_number: 2, day_of_week: 3)
    assert_equal 11, setup.day_of_current_month(Date.new(2026, 3, 1))
  end

  # Week 3

  test "day_of_current_month week 3 Monday returns third Monday" do
    setup = PriestSetup.new(week_number: 3, day_of_week: 1)
    assert_equal 20, setup.day_of_current_month(Date.new(2026, 4, 1))
  end

  test "day_of_current_month week 3 Wednesday returns third Wednesday" do
    setup = PriestSetup.new(week_number: 3, day_of_week: 3)
    assert_equal 15, setup.day_of_current_month(Date.new(2026, 4, 1))
  end

  # Week 4

  test "day_of_current_month week 4 Monday returns fourth Monday" do
    setup = PriestSetup.new(week_number: 4, day_of_week: 1)
    assert_equal 27, setup.day_of_current_month(Date.new(2026, 4, 1))
  end

  test "day_of_current_month week 4 Wednesday returns fourth Wednesday" do
    setup = PriestSetup.new(week_number: 4, day_of_week: 3)
    assert_equal 22, setup.day_of_current_month(Date.new(2026, 4, 1))
  end

  # Week 5 — last occurrence in the month (last_week? branch)
  # April 2026 eom = April 30 (Thursday, cwday=4)

  test "day_of_current_month week 5 returns last Monday in April" do
    setup = PriestSetup.new(week_number: 5, day_of_week: 1)
    assert_equal 27, setup.day_of_current_month(Date.new(2026, 4, 1))
  end

  test "day_of_current_month week 5 returns last Wednesday in April" do
    travel_to Time.zone.parse("2026-04-01") do
      setup = PriestSetup.new(week_number: 5, day_of_week: 3)
      assert_equal 29, setup.day_of_current_month
    end
  end

  test "day_of_current_month week 5 returns last Thursday in April which is eom" do
    setup = PriestSetup.new(week_number: 5, day_of_week: 4)
    assert_equal 30, setup.day_of_current_month(Date.new(2026, 4, 1))
  end

  test "day_of_current_month week 5 returns last Friday in April" do
    travel_to Time.zone.parse("2026-04-01") do
      setup = PriestSetup.new(week_number: 5, day_of_week: 5)
      assert_equal 24, setup.day_of_current_month
    end
  end

  # March 2026 eom = March 31 (Tuesday, cwday=2)

  test "day_of_current_month week 5 returns last Tuesday in March which is eom" do
    setup = PriestSetup.new(week_number: 5, day_of_week: 2)
    assert_equal 31, setup.day_of_current_month(Date.new(2026, 3, 1))
  end

  test "day_of_current_month week 5 returns last Monday in March" do
    setup = PriestSetup.new(week_number: 5, day_of_week: 1)
    assert_equal 30, setup.day_of_current_month(Date.new(2026, 3, 1))
  end

  test "day_of_current_month week 5 returns last Wednesday in March" do
    setup = PriestSetup.new(week_number: 5, day_of_week: 3)
    assert_equal 25, setup.day_of_current_month(Date.new(2026, 3, 1))
  end

  # Reference parameter — same setup, different months

  test "day_of_current_month respects reference month for Wednesday week 1" do
    setup = PriestSetup.new(week_number: 1, day_of_week: 3)
    assert_equal 1,  setup.day_of_current_month(Date.new(2026, 4, 1))  # April 1
    assert_equal 4,  setup.day_of_current_month(Date.new(2026, 3, 1))  # March 4
  end

  test "is valid with other valid attributes" do
    travel_to Date.new(2026, 3, 10) do
      priest_setup = PriestSetup.new(priest: users(:priest_one), week_number: 6, day_of_week: 2)
      assert priest_setup.valid?
    end
  end

  # Tests for week_number/day_of_week presence conditional on day_of_month

  test "is valid without week_number and day_of_week when day_of_month is present" do
    priest_setup = PriestSetup.new(priest: users(:priest_one), week_number: nil, day_of_week: nil, day_of_month: 15)
    assert priest_setup.valid?
  end

  test "is invalid without week_number when day_of_month is absent" do
    priest_setup = PriestSetup.new(priest: users(:priest_one), week_number: nil, day_of_week: 3)
    assert_not priest_setup.valid?
    assert priest_setup.errors[:week_number].any?
  end

  test "is invalid without day_of_week when day_of_month is absent" do
    priest_setup = PriestSetup.new(priest: users(:priest_one), week_number: 2, day_of_week: nil)
    assert_not priest_setup.valid?
    assert priest_setup.errors[:day_of_week].any?
  end

  test "is invalid without both week_number and day_of_week when day_of_month is absent" do
    priest_setup = PriestSetup.new(priest: users(:priest_one), week_number: nil, day_of_week: nil)
    assert_not priest_setup.valid?
    assert priest_setup.errors[:week_number].any?
    assert priest_setup.errors[:day_of_week].any?
  end

  # Tests for week_and_day_of_month
  # March 2026: starts on Sunday (wday=0)

  test "week_and_day_of_month returns week and day from day_of_month" do
    travel_to Date.new(2026, 3, 10) do
      # March 15 is the 3rd Sunday (wday=0)
      setup = PriestSetup.new(day_of_month: 15)
      assert_equal [ 3, 7 ], setup.week_and_day_of_month
    end
  end

  test "week_and_day_of_month returns correct values for first day of month" do
    travel_to Date.new(2026, 3, 10) do
      # March 1 is the 1st Sunday (wday=0)
      setup = PriestSetup.new(day_of_month: 1)
      assert_equal [ 1, 7 ], setup.week_and_day_of_month
    end
  end

  test "week_and_day_of_month returns correct values for last day of month" do
    travel_to Date.new(2026, 3, 10) do
      # March 31 is the 5th Tuesday (cwday=2): first Tuesday = March 3, +28 days = March 31
      setup = PriestSetup.new(day_of_month: 31)
      assert_equal [ 5, 2 ], setup.week_and_day_of_month
    end
  end

  test "week_and_day_of_month returns correct values for 29th day of month" do
    travel_to Date.new(2026, 3, 10) do
      # March 31 is the 5th Tuesday (wday=2)
      setup = PriestSetup.new(day_of_month: 29)
      assert_equal [ 5, 7 ], setup.week_and_day_of_month
    end
  end


  test "week_and_day_of_month returns week_number and day_of_week when day_of_month is absent" do
    setup = PriestSetup.new(week_number: 2, day_of_week: 4)
    assert_equal [ 2, 4 ], setup.week_and_day_of_month
  end

  test "week_and_day_of_month returns correct values for 31th day of month" do
    travel_to Date.new(2026, 3, 10) do
      # March 31 is the 5th Tuesday (wday=2)
      setup = PriestSetup.new(day_of_month: 29)
      assert_equal [ 5, 7 ], setup.week_and_day_of_month
    end
  end
end
