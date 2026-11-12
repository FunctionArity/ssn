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
    guard = Guard.new(day_number: 1, due_date: Date.current, vocal: users(:one), priest: users(:two), guard_setup: guard_setups(:one))
    guard.guardians << users(:one)

    assert guard.valid?
  end

  test "doesn't allow opening a second guard for the same day" do
    guard = Guard.new(day_number: 1, due_date: guards(:one).due_date, vocal: users(:one), priest: users(:two), guard_setup: guard_setups(:one))
    guard.guardians << users(:one)

    assert_not guard.valid?
    assert_includes guard.errors[:due_date], I18n.t("activerecord.errors.models.guard.attributes.due_date.open_guard_taken")
  end

  test "allows a guard for a day whose other guard is closed" do
    guards(:one).closed!
    guard = Guard.new(day_number: 1, due_date: guards(:one).due_date, vocal: users(:one), priest: users(:two), guard_setup: guard_setups(:one))
    guard.guardians << users(:one)

    assert guard.valid?
  end

  test "doesn't allow reopening a guard while another one is open for the same day" do
    closed = Guard.new(day_number: 1, due_date: guards(:one).due_date, status: :closed, vocal: users(:one), priest: users(:two), guard_setup: guard_setups(:one))
    closed.guardians << users(:one)
    closed.save!

    assert_not closed.update(status: :open)
    assert closed.errors[:due_date].any?
  end

  test "records a version with the changed attributes on update" do
    guard = guards(:one)

    assert_difference -> { guard.versions.count }, 1 do
      guard.update!(notes: "Notas nuevas")
    end

    changes = guard.versions.last.object_changes
    assert_equal [ "Test guard notes", "Notas nuevas" ], changes["notes"]
    assert_not changes.key?("updated_at")
  end

  test "records the status change when the guard is closed" do
    guard = guards(:one)
    guard.closed!

    assert_equal %w[open closed], guard.versions.last.object_changes["status"]
  end

  # On day 28 and later, the priest is the one set up for that day of the month. A setup for a day the month doesn't
  # have falls on its last day, so it gets that day's priest.
  test "in a month with 31 days, guards on days 28 to 31 get each day's priest" do
    assert_end_of_month_priests Date.new(2027, 1, 10), 28 => 28, 29 => 29, 30 => 30, 31 => 31
  end

  test "in a month with 30 days, a guard for the 31st gets the 30th's priest" do
    assert_end_of_month_priests Date.new(2027, 4, 10), 28 => 28, 29 => 29, 30 => 30, 31 => 30
  end

  test "in a February with 28 days, guards for the 29th to the 31st get the 28th's priest" do
    assert_end_of_month_priests Date.new(2027, 2, 10), 28 => 28, 29 => 28, 30 => 28, 31 => 28
  end

  private

  # Sets up a different priest for each of the days 28 to 31, then checks the priest a new guard gets from the setup
  # of each day, on the given date: days maps each setup's day to the day whose priest it should get.
  def assert_end_of_month_priests(today, days)
    priests = (28..31).index_with do |day|
      priest = User.create!(email: "priest#{day}@example.test", first_name: "Priest", last_name: day.to_s, role: :priest, password: "password123")
      PriestSetup.create!(day_of_month: day, priest: priest)
      priest
    end

    travel_to today do
      days.each do |setup_day, priest_day|
        setup = GuardSetup.new(day_number: setup_day, vocal: users(:one))

        guard = Guard.new(guard_setup: setup)

        assert_equal today.change(day: priest_day), setup.due_date, "due date of the day #{setup_day} setup"
        assert_equal priests[priest_day], guard.priest, "priest of the day #{setup_day} guard"
      end
    end
  end
end
