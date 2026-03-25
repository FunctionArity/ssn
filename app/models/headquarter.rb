class Headquarter < ApplicationRecord
  belongs_to :president, class_name: "User"

  validates :name, presence: true
end
