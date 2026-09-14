class MoveUserToGuardSetupService
  def initialize(user, day_number)
    @user = user
    @guard_setup = GuardSetup.find_by(day_number: day_number)
  end

  def call
    return if @guard_setup.nil? || @user.guard_setups.include?(@guard_setup)

    @user.guard_setup_guardians.destroy_all
    @user.guard_setups << @guard_setup
  end
end
