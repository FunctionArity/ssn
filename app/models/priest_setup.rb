class PriestSetup < ApplicationRecord
  WEEK_NAMES = %w[First Second Third Fourth Fifth].freeze
  DAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  belongs_to :priest, class_name: "User"

  validates :week_number, presence: true, inclusion: { in: 1..6 }
  validates :day_of_week, presence: true, inclusion: { in: 1..7 }
  validates :week_number, uniqueness: { scope: :day_of_week }

  def self.find_priest_by_week_and_day(day_of_week, week_number)
    find_by(week_number: week_number, day_of_week: day_of_week)&.priest
  end

  def description
    "#{WEEK_NAMES[week_number - 1]} #{DAY_NAMES[day_of_week]}"
  end
end
