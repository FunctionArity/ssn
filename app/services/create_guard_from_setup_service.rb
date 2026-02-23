class CreateGuardFromSetupService
  def initialize(guard_setup_id)
    @guard_setup = GuardSetup.find(guard_setup_id)
  end

  def call
    ActiveRecord::Base.transaction do
      guard = Guard.new(
        day_number: @guard_setup.day_number,
        notes: @guard_setup.notes,
        vocal: @guard_setup.vocal,
        priest: @guard_setup.priest,
        guardian_ids: @guard_setup.guardian_ids
      )

      guard
    end
  end
end
