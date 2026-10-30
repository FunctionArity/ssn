class Service < ApplicationRecord
  belongs_to :guard
  belongs_to :created_by, class_name: "User"
  belongs_to :health_facility, optional: true

  acts_as_list scope: :guard_id
  has_paper_trail ignore: %i[position updated_at]

  enum :status, { pending: 0, completed: 1 }, default: :pending

  validates :full_name, :due_date, :status, presence: true
  validate :guard_must_be_open, on: :update, if: :will_save_change_to_guard_id?

  before_validation :clear_blank_comments
  after_update_commit :broadcast_changes

  # Every typed word must appear, in any order and ignoring case and accents: "rodriguez pablo" finds "Pablo Rodríguez".
  scope :search_by_full_name, ->(query) {
    query.split.reduce(all) do |relation, word|
      relation.where("translate(lower(services.full_name), 'áéíóúüñ', 'aeiouun') LIKE translate(lower(?), 'áéíóúüñ', 'aeiouun')", "%#{sanitize_sql_like(word)}%")
    end
  }
  scope :search_by_health_facility, ->(query) { joins(:health_facility).where("health_facilities.name ILIKE ?", "%#{sanitize_sql_like(query)}%") }
  scope :search_by_guard_day, ->(day) { joins(:guard).where(guards: { day_number: day }) }

  # Phones are stored as typed, so "261-555" has to match "261 555 1234".
  scope :search_by_caller_phone, ->(query) {
    digits = query.gsub(/\D/, "")
    digits.empty? ? none : where("regexp_replace(services.caller_phone, '\\D', '', 'g') LIKE ?", "%#{digits}%")
  }

  def self.search(filters)
    scope = all
    scope = scope.search_by_full_name(filters[:full_name]) if filters[:full_name].present?
    scope = scope.search_by_health_facility(filters[:health_facility]) if filters[:health_facility].present?
    scope = scope.where(due_date: filters[:date]) if filters[:date].present?
    scope = scope.search_by_guard_day(filters[:guard_day]) if filters[:guard_day].present?
    scope = scope.search_by_caller_phone(filters[:caller_phone]) if filters[:caller_phone].present?
    scope
  end

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

  # The rich text editor submits markup like "<p><br></p>" when the comment is empty.
  def clear_blank_comments
    self.comments = nil if comments.present? && ActionController::Base.helpers.strip_tags(comments).gsub(/[[:space:]]|&nbsp;/, "").empty?
  end

  def guard_must_be_open
    errors.add(:guard, :must_be_open) if guard&.closed?
  end
end
