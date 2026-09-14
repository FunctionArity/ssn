require "test_helper"

class MoveUserToGuardSetupServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @old_setup = guard_setups(:one)
    @new_setup = guard_setups(:two)
  end

  test "moves the user from their current guard setup to the new one" do
    assert_equal [ @old_setup ], @user.guard_setups.to_a

    MoveUserToGuardSetupService.new(@user, @new_setup.day_number).call

    assert_equal [ @new_setup ], @user.reload.guard_setups.to_a
  end

  test "assigns the guard setup when the user had none before" do
    other_user = users(:agustin)
    assert_empty other_user.guard_setups

    MoveUserToGuardSetupService.new(other_user, @new_setup.day_number).call

    assert_equal [ @new_setup ], other_user.reload.guard_setups.to_a
  end

  test "does nothing when the day number does not match any guard setup" do
    MoveUserToGuardSetupService.new(@user, 999).call

    assert_equal [ @old_setup ], @user.reload.guard_setups.to_a
  end

  test "does nothing when the user is already in the target guard setup" do
    assert_no_changes -> { @user.reload.guard_setups.to_a } do
      MoveUserToGuardSetupService.new(@user, @old_setup.day_number).call
    end
  end

  test "does not remove the old guard setup's other guardians" do
    guard_setup_guardians(:one)
    GuardSetupGuardian.create!(guard_setup: @old_setup, user: users(:agustin))

    MoveUserToGuardSetupService.new(@user, @new_setup.day_number).call

    assert_equal [ users(:agustin) ], @old_setup.reload.guardians
  end
end
