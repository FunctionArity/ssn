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

  test "records a version with the changed attributes on update" do
    service = services(:one)

    assert_difference -> { service.versions.count }, 1 do
      service.update!(full_name: "Nombre Nuevo")
    end

    changes = service.versions.last.object_changes
    assert_equal [ services(:one).full_name_before_last_save, "Nombre Nuevo" ], changes["full_name"]
    assert_not changes.key?("updated_at")
  end

  test "does not record a version when only the position changes" do
    service = services(:one)

    assert_no_difference -> { service.versions.count } do
      service.update!(position: service.position + 1)
    end
  end
end
