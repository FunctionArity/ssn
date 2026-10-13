class ContactGroup < ApplicationRecord
  belongs_to :contact_directory, inverse_of: :contact_groups
  has_many :contacts, -> { order(:position) }, dependent: :destroy, inverse_of: :contact_group

  accepts_nested_attributes_for :contacts, allow_destroy: true, reject_if: :all_blank

  acts_as_list scope: :contact_directory
  has_paper_trail ignore: %i[position updated_at]

  validates :name, presence: true
end
