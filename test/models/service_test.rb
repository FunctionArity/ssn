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
end
