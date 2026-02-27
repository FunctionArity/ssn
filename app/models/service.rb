class Service < ApplicationRecord
  belongs_to :guard
  belongs_to :created_by, class_name: "User"

  enum :status, { pending: 0, completed: 1 }, default: :pending
  enum :place, { home: 0, hospital: 1, nursing_home: 2, other: 3 }

  validates :full_name, :due_date, :status, presence: true
end
