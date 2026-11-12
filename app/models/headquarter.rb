class Headquarter < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  has_many :contact_directories, -> { order(:position) }, dependent: :destroy

  # The sede's own data. Sedes that have any can't be deleted.
  has_many :users, dependent: :restrict_with_error
  has_many :guard_setups, dependent: :restrict_with_error
  has_many :guards, dependent: :restrict_with_error
  has_many :services, dependent: :restrict_with_error
  has_many :priest_setups, dependent: :restrict_with_error

  validates :country, :state, :city, :address, presence: true
  validate :contact_method_present

  private

  def slug_candidates
    [
      :city,
      [ :city, :state ],
      [ :city, :state, :country ]
    ]
  end

  def contact_method_present
    return if phone.present? || email.present? || whatsapp.present?

    errors.add(:base, :missing_contact)
  end
end
