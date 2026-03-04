class HealthFacility < ApplicationRecord
  validates :name, :address, presence: true
end
