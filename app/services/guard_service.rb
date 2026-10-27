class GuardService
  OPENED_WINDOW = 12.hours

  # Open guards a new service can be assigned to: the guard whose day started in the last 12 hours,
  # and guards for later days. Based on the guard's day, not when the record was created.
  def self.assignable(now = Time.current)
    Guard.open
         .where(due_date: (now - OPENED_WINDOW).to_date..)
         .order(due_date: :desc, created_at: :desc)
  end
end
