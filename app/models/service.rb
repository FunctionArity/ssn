class Service < ApplicationRecord
  belongs_to :guard
  belongs_to :created_by, class_name: "User"
  belongs_to :health_facility, optional: true

  acts_as_list scope: :guard_id

  enum :status, { pending: 0, completed: 1 }, default: :pending

  validates :full_name, :due_date, :status, presence: true

  after_update_commit -> {
    broadcast_replace_later_to "services",
      partial: "services/small_view",
      locals: { service: self }
  }
end
