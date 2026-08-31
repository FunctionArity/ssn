class Headquarter < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

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
