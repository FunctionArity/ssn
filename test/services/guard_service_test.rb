require "test_helper"

class GuardServiceTest < ActiveSupport::TestCase
  setup do
    @guard = guards(:one)
  end

  test "includes yesterday's guard while still within 12 hours of today's start" do
    @guard.update_columns(due_date: Date.new(2026, 10, 26))

    assert_includes GuardService.assignable(Time.zone.local(2026, 10, 27, 2, 0)), @guard
  end

  test "excludes yesterday's guard once 12 hours of today have passed" do
    @guard.update_columns(due_date: Date.new(2026, 10, 26))

    assert_not_includes GuardService.assignable(Time.zone.local(2026, 10, 27, 13, 0)), @guard
  end

  test "includes today's and future guards" do
    now = Time.zone.local(2026, 10, 26, 23, 30)
    @guard.update_columns(due_date: Date.new(2026, 10, 26))
    future = create_guard(due_date: Date.new(2026, 10, 27))

    assert_equal [ future, @guard ], GuardService.assignable(now).to_a
  end

  test "excludes an old guard even when its record was just created" do
    now = Time.zone.local(2026, 10, 26, 23, 30)
    @guard.update_columns(due_date: Date.new(2026, 10, 21), created_at: now - 5.minutes)

    assert_not_includes GuardService.assignable(now), @guard
  end

  test "excludes closed guards" do
    @guard.update_columns(due_date: Date.new(2026, 10, 27), status: Guard.statuses[:closed])

    assert_not_includes GuardService.assignable(Time.zone.local(2026, 10, 27, 2, 0)), @guard
  end

  private

  def create_guard(due_date:)
    Guard.create!(day_number: due_date.day, due_date: due_date, vocal: users(:one), priest: users(:two),
                  guard_setup: guard_setups(:one), guardians: [ users(:one) ])
  end
end
