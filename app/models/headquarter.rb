class Headquarter < ApplicationRecord
  belongs_to :president, class_name: "User"
  has_many :users, dependent: :restrict_with_error

  validates :name, presence: true
end
