class CreateGuardFromSetupService
  def initialize(guard_setup_id)
    @guard_setup = if guard_setup_id.present?
                     GuardSetup.find(guard_setup_id)
    else
                     GuardSetup.find_by(day_number: Date.current.day)
    end
  end

  def call
    ActiveRecord::Base.transaction do
      guard = Guard.new(
        day_number: @guard_setup.day_number,
        due_date: Date.current,
        notes: @guard_setup.notes,
        vocal: @guard_setup.vocal,
        priest: User.current_priest,
        guardian_ids: @guard_setup.guardian_ids,
        guard_setup_id: @guard_setup.id
      )

      guard
    end
  end
end
