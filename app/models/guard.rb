class Guard < ApplicationRecord
  belongs_to :vocal, class_name: "User"
  belongs_to :priest, class_name: "User"
  has_many :guard_guardians, dependent: :destroy
  has_many :guardians, through: :guard_guardians, source: :user

  validates :day, presence: true
  validate :at_least_one_guardian

  private

  def at_least_one_guardian
    errors.add(:guardians, :blank) if guardians.empty? && guard_guardians.empty?
  end
end
