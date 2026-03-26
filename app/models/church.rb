class Church < ApplicationRecord
  belongs_to :headquarter

  has_many :priests, class_name: "User", foreign_key: :church_id, dependent: :nullify

  validates :name, presence: true
end
