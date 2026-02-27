class GuardService
  def self.current
    Guard.find_by(due_date: Date.current)
  end
end
