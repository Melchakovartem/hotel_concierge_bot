class Department < ApplicationRecord
  belongs_to :hotel

  has_many :tickets, dependent: :restrict_with_exception
end
