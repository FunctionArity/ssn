class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :invitable, :database_authenticatable,
         :recoverable, :rememberable, :validatable, :lockable, :trackable

  has_one_attached :avatar, service: :amazon_avatar

  enum :role, { guardian: 0, vocal: 1, priest: 2 }, default: :guardian
  enum :user_type, { regular: 0, admin: 1, super_admin: 2 }, default: :regular

  validates :first_name, :last_name, presence: true

  scope :guardians, -> { where(role: :guardian) }
  scope :vocals, -> { where(role: :vocal) }
  scope :priests, -> { where(role: :priest) }
  scope :priests_without_setup, -> { priests.where.not(id: PriestSetup.select(:priest_id)) }

  belongs_to :church, optional: true

  has_many :guard_guardians, dependent: :destroy
  has_many :guards, through: :guard_guardians

  has_many :vocal_guard_setups, class_name: "GuardSetup", foreign_key: :vocal_id, dependent: :nullify, inverse_of: :vocal

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
    "#{last_name} #{first_name}"
  end

  def initials
    "#{last_name[0]}#{first_name[0]}"
  end

  def day_numbers
    (vocal_guard_setups + guard_setups).map(&:day_number).join(" ")
  end

  def self.current_priest(date = Date.current)
    if date.day >= 28
      PriestSetup.where(day_of_month: date.day).first&.priest
    else
      week_day = ((date.wday - 1) % 7) + 1
      week_month = week_of_month(date)
      PriestSetup.find_priest_by_week_and_day(week_day, week_month)
    end
  end

  def self.week_of_month(date)
    bom = date.beginning_of_month
    first_occurrence = bom + ((date.cwday - bom.cwday) % 7)
    ((date - first_occurrence) / 7).floor + 1
  end
end
