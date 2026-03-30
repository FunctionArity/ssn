class Guard < ApplicationRecord
  belongs_to :vocal, class_name: "User"
  belongs_to :priest, class_name: "User"
  belongs_to :guard_setup, optional: true
  has_many :guard_guardians, dependent: :destroy
  has_many :guardians, through: :guard_guardians, source: :user
  has_many :services, dependent: :destroy
  has_one_attached :pdf_file

  enum :status, { open: 0, closed: 1 }, default: :open

  after_initialize :set_defaults_from_setup, if: ->{ :new_record? && guard_setup.present? }

  validates :day_number, presence: true
  validates :due_date, presence: true
  validate :at_least_one_guardian


  private

  def set_defaults_from_setup
    self.priest = User.current_priest(guard_setup.due_date)
  end

  def at_least_one_guardian
    errors.add(:guardians, :blank) if guardians.empty? && guard_guardians.empty?
  end
end
