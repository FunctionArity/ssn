# A named list of contacts kept by a headquarter (e.g. "Referentes Pastoral de la Salud"),
# organized in groups whose name each headquarter chooses through group_label (decanato, zona…).
class ContactDirectory < ApplicationRecord
  belongs_to :headquarter
  has_many :contact_groups, -> { order(:position) }, dependent: :destroy, inverse_of: :contact_directory

  accepts_nested_attributes_for :contact_groups, allow_destroy: true, reject_if: :all_blank

  acts_as_list scope: :headquarter
  has_paper_trail ignore: %i[position updated_at]

  enum :visibility, { members: 0, public: 1 }, prefix: true, default: :members, validate: true

  validates :title, presence: true

  def group_label_or_default
    group_label.presence || self.class.human_attribute_name(:default_group_label)
  end
end
