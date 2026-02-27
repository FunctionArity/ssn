require "test_helper"

class CreateGuardFromSetupServiceTest < ActiveSupport::TestCase
  setup do
    @guard_setup = guard_setups(:one)
  end

  test "builds a guard with attributes from the guard setup" do
    guard = CreateGuardFromSetupService.new(@guard_setup.id).call

    assert_equal @guard_setup.day_number, guard.day_number
    assert_equal @guard_setup.notes, guard.notes
    assert_equal @guard_setup.vocal, guard.vocal
  end

  test "builds a guard with the same guardians as the setup" do
    guard = CreateGuardFromSetupService.new(@guard_setup.id).call

    assert_equal @guard_setup.guardian_ids.sort, guard.guardian_ids.sort
  end

  test "does not persist the guard" do
    guard = CreateGuardFromSetupService.new(@guard_setup.id).call

    assert guard.new_record?
  end

  test "raises ActiveRecord::RecordNotFound when guard setup does not exist" do
    assert_raises(ActiveRecord::RecordNotFound) do
      CreateGuardFromSetupService.new(-1).call
    end
  end
end
