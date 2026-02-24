class GuardSetup < ApplicationRecord
  belongs_to :vocal, class_name: "User"
  belongs_to :priest, class_name: "User"
  has_many :guard_setup_guardians, dependent: :destroy
  has_many :guardians, through: :guard_setup_guardians, source: :user
  has_many :guards, dependent: :destroy

  validates :day_number, presence: true
  validate :at_least_one_guardian

  private

  def at_least_one_guardian
    errors.add(:guardians, :blank) if guardians.empty? && guard_setup_guardians.empty?
  end
end
