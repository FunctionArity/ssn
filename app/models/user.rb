class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { guardian: 0, vocal: 1, priest: 2 }, default: :guardian

  validates :first_name, :last_name, presence: true

  scope :guardians, -> { where(role: :guardian) }
  scope :vocals, -> { where(role: :vocal) }
  scope :priests, -> { where(role: :priest) }
  scope :priests_without_setup, -> { priests.where.not(id: PriestSetup.select(:priest_id)) }

  belongs_to :church, optional: true

  has_many :guard_guardians, dependent: :destroy
  has_many :guards, through: :guard_guardians

  has_many :guard_setup_guardians, dependent: :destroy
  has_many :guard_setups, through: :guard_setup_guardians

  def role_badge_class
    case role
    when "guardian" then "badge_green"
    when "vocal"    then "badge_red"
    when "priest"   then "badge_purple"
    end
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def self.current_priest(date = Date.current)
    week_day = ((date.wday - 1) % 7) + 1
    week_month = week_of_month(date)
    PriestSetup.find_priest_by_week_and_day(week_day, week_month)
  end

  def self.week_of_month(date)
    first_monday = date.beginning_of_month.beginning_of_week
    ((date - first_monday) / 7).floor + 1
  end
end
