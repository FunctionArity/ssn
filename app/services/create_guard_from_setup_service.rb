class CreateGuardFromSetupService
  def initialize(guard_setup_id = nil)
    @due_date = Date.current
    @guard_setup = if guard_setup_id.present?
                     GuardSetup.find(guard_setup_id)
    else
                     GuardSetup.find_by(day_number: @due_date.day)
    end
  end

  def guard_setup?
    @guard_setup.present?
  end

  def call
    Guard.new(
      day_number: @guard_setup.day_number,
      due_date: @guard_setup.due_date,
      notes: @guard_setup.notes,
      vocal: @guard_setup.vocal,
      guardian_ids: @guard_setup.guardian_ids,
      guard_setup_id: @guard_setup.id
    )
  end
end
