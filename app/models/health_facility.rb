class HealthFacility < ApplicationRecord
  belongs_to :headquarter

  validates :name, :address, presence: true
end
