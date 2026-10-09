require "test_helper"

class ServiceTest < ActiveSupport::TestCase
  test "can be completed when its guard is open" do
    service = services(:one)
    service.guard.update_column(:status, Guard.statuses[:open])

    assert service.can_be_completed?
  end

  test "cannot be completed when its guard is closed" do
    service = services(:one)
    service.guard.update_column(:status, Guard.statuses[:closed])

    assert_not service.can_be_completed?
  end

  test "cannot be moved to a closed guard" do
    service = services(:one)
    closed_guard = Guard.create!(day_number: 2, due_date: Date.current - 1, status: :closed,
                                 vocal: users(:one), priest: users(:two), guard_setup: guard_setups(:one), guardians: [ users(:one) ])

    assert_not service.update(guard: closed_guard)
    assert service.errors[:guard].any?
  end

  test "can be moved to an open guard" do
    service = services(:one)
    open_guard = Guard.create!(day_number: 2, due_date: Date.current, status: :open,
                               vocal: users(:one), priest: users(:two), guard_setup: guard_setups(:one), guardians: [ users(:one) ])

    assert service.update(guard: open_guard)
  end
end
