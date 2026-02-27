class Service < ApplicationRecord
  belongs_to :guard
  belongs_to :created_by, class_name: "User"
  belongs_to :health_facility, optional: true

  enum :status, { pending: 0, completed: 1 }, default: :pending

  validates :full_name, :due_date, :status, presence: true
end
