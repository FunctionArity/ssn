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
end
