class PriestSetup < ApplicationRecord
  WEEK_NAMES = %w[First Second Third Fourth].freeze
  DAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  belongs_to :priest, class_name: "User"

  validates :week_number, presence: true, inclusion: { in: 1..4 }
  validates :day_of_week, presence: true, inclusion: { in: 0..6 }
  validates :week_number, uniqueness: { scope: :day_of_week }

  def description
    "#{WEEK_NAMES[week_number - 1]} #{DAY_NAMES[day_of_week]}"
  end
end
