class CreateGuardFromSetupService
  def initialize(guard_setup_id, due_date = Date.current)
    @due_date = due_date
    @guard_setup = if guard_setup_id.present?
                     GuardSetup.find(guard_setup_id)
    else
                     GuardSetup.find_by(day_number: @due_date.day)
    end
  end

  def call
    priest = User.current_priest(@due_date)
    return Guard.new(due_date: @due_date, priest: priest, day_number: @due_date.day) if @guard_setup.nil?

    Guard.new(
      day_number: @due_date.day,
      due_date: @due_date,
      notes: @guard_setup.notes,
      vocal: @guard_setup.vocal,
      priest: priest,
      guardian_ids: @guard_setup.guardian_ids,
      guard_setup_id: @guard_setup.id
    )
  end
end
