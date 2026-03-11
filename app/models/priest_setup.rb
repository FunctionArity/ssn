class PriestSetup < ApplicationRecord
  WEEK_NAMES = %w[First Second Third Fourth Fifth Sixth].freeze
  DAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  belongs_to :priest, class_name: "User"

  before_validation :set_day_of_month, if: -> { day_of_month.nil? && day_of_week.present? && week_number.present? }

  validates :week_number, inclusion: { in: 1..6 }, allow_nil: true
  validates :day_of_week, inclusion: { in: 1..7 }, allow_nil: true
  validates :week_number, presence: true, unless: -> { day_of_month.present? }
  validates :day_of_week, presence: true, unless: -> { day_of_month.present? }
  # validates :week_number, uniqueness: { scope: :day_of_week }

  def self.find_priest_by_week_and_day(day_of_week, week_number)
    find_by(week_number: week_number, day_of_week: day_of_week)&.priest
  end

  def set_day_of_month
    day = day_of_current_month
    return if day.nil? || day <= 28

    self.day_of_week = nil
    self.week_number = nil
    self.day_of_month = day
  end

  def day_of_current_month
    first_day = Date.today.beginning_of_month
    first_occurrence = first_day + ((day_of_week - first_day.cwday) % 7)
    target = first_occurrence + ((week_number - 2) * 7)
    target.day if target.month == first_day.month
  end

  def week_and_day_of_month
    return [ week_number, day_of_week ] unless day_of_month.present?

    day_info = week_and_day_info(date)

    [ day_info[:week_of_month], day_info[:day_of_week] ]
  end

  def date
    Date.today.beginning_of_month + (day_of_month - 1)
  end

  def week_and_day_info(date = Date.today)
    day_of_week = date.cwday # 1 = Monday, 7 = Sunday (ISO 8601)

    first_day_of_month = Date.new(date.year, date.month, 1)
    first_day_cwday = first_day_of_month.cwday # weekday of the 1st

    week_of_month = ((date.day + first_day_cwday - 2) / 7) + 1

    {
      date: date,
      day_of_month: date.day,
      week_of_month: week_of_month,
      day_of_week: day_of_week,
      day_name: date.strftime("%A"),
      week_label: "Week #{week_of_month} of #{date.strftime('%B')}"
    }
  end

  def description
    "#{WEEK_NAMES[week_number - 1]} #{DAY_NAMES[day_of_week]}"
  end
end
