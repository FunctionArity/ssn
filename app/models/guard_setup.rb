class GuardSetup < ApplicationRecord
  GUARD_NUMBER = 26073
  acts_as_tenant :headquarter
  belongs_to :vocal, class_name: "User"

  has_many :guard_setup_guardians, dependent: :destroy
  has_many :guardians, through: :guard_setup_guardians, source: :user
  has_many :guards, dependent: :destroy

  scope :before_day, ->(day) { where("day_number < ?", day).order(day_number: :desc) }
  scope :after_day, ->(day) { where("day_number > ?", day).order(:day_number) }

  validates :day_number, presence: true
  validate :at_least_one_guardian

  # This month's date for the setup's day. Months without that day (the 29th to the 31st) use their last day.
  def due_date
    today = Date.current
    today.change(day: [ day_number, today.end_of_month.day ].min)
  end

  private

  def at_least_one_guardian
    errors.add(:guardians, :blank) if guardians.empty? && guard_setup_guardians.empty?
  end
end
