class PriestSetup < ApplicationRecord
  WEEK_NAMES = %w[First Second Third Fourth Fifth Sixth].freeze
  DAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  belongs_to :priest, class_name: "User"

  validates :week_number, inclusion: { in: 1..6 }, allow_nil: true
  validates :day_of_week, inclusion: { in: 1..7 }, allow_nil: true
  validates :week_number, presence: true, unless: -> { day_of_month.present? }
  validates :day_of_week, presence: true, unless: -> { day_of_month.present? }
  # validates :week_number, uniqueness: { scope: :day_of_week }

  def self.find_priest_by_week_and_day(day_of_week, week_number)
    find_by(week_number: week_number, day_of_week: day_of_week)&.priest
  end

  def self.find_priest_by_day_of_month(date = Date.current)
    PriestSetup.where(day_of_month: date.day).first&.priest
  end

  def set_day_of_month
    day = day_of_current_month
    return if day.nil? || day <= 28

    self.day_of_month = day
  end

  def day_of_current_month(reference = Date.today)
    bom = reference.beginning_of_month
    days_until_target = (day_of_week - bom.cwday) % 7
    first_occurrence = bom + days_until_target

    target = last_week? ? bom + 27.days + day_of_week : first_occurrence + ((week_number - 1) * 7)

    return target.day if target.month == reference.month

    fallback_day = { 1 => 29, 2 => 30, 3 => 31 }[day_of_week]
    return nil if day_of_week > 3 || fallback_day > reference.end_of_month.day

    fallback_day
  end

  def current_date(reference = Date.today)
    day = day_of_current_month(reference)
    return nil if day.nil?

    reference.change(day: day)
  end

  def date
    Date.today.beginning_of_month + (day_of_month - 1)
  end

  def description
    "#{WEEK_NAMES[week_number - 1]} #{DAY_NAMES[day_of_week]}"
  end

  def last_week?
    week_number > 4
  end
end
