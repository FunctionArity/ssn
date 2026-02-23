class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { guardian: 0, vocal: 1, priest: 2 }, default: :guardian

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
end
