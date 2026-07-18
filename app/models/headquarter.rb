class Headquarter < ApplicationRecord
  validates :country, :state, :city, :address, presence: true
  validate :contact_method_present

  private

  def contact_method_present
    return if phone.present? || email.present? || whatsapp.present?

    errors.add(:base, :missing_contact)
  end
end
