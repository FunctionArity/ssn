class Service < ApplicationRecord
  belongs_to :guard
  belongs_to :created_by, class_name: "User"
  belongs_to :health_facility, optional: true

  acts_as_list scope: :guard_id
  has_paper_trail ignore: %i[position updated_at]

  enum :status, { pending: 0, completed: 1 }, default: :pending

  validates :full_name, :due_date, :status, presence: true
  validate :guard_must_be_open, on: :update, if: :will_save_change_to_guard_id?

  after_update_commit :broadcast_changes

  def can_be_completed?
    pending? && guard.open?
  end

  private

  def broadcast_changes
    broadcast_replace_later_to "services",
      partial: "services/small_view",
      locals: { service: self }
    broadcast_guard_services_lists
  end

  # Keeps the guard show page in sync; when the service moves to another guard, both lists change.
  def broadcast_guard_services_lists
    broadcast_guard_services_list(guard)

    previous_guard_id = saved_change_to_guard_id&.first
    broadcast_guard_services_list(Guard.find(previous_guard_id)) if previous_guard_id
  end

  def broadcast_guard_services_list(guard)
    broadcast_replace_later_to "guard_#{guard.id}",
      target: "guard_#{guard.id}_services",
      partial: "guards/services_list",
      locals: { guard: guard, services: guard.services.includes(:health_facility).order(:position).to_a }
  end

  def guard_must_be_open
    errors.add(:guard, :must_be_open) if guard&.closed?
  end
end
