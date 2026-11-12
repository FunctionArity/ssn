class HealthFacility < ApplicationRecord
  acts_as_tenant :headquarter

  validates :name, :address, presence: true

  scope :search_by_name, ->(query) {
    where("name ILIKE :q", q: "%#{sanitize_sql_like(query)}%")
  }
end
