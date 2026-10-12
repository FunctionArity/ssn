class Contact < ApplicationRecord
  belongs_to :contact_group, inverse_of: :contacts

  acts_as_list scope: :contact_group
  has_paper_trail ignore: %i[position updated_at]

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  # Digits for tel: and WhatsApp links, e.g. "261 5087203" => "2615087203".
  def phone_digits
    phone.to_s.gsub(/\D/, "")
  end
end
