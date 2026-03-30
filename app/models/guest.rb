class Guest < ApplicationRecord
  belongs_to :hotel

  has_many :conversations, dependent: :restrict_with_exception
  has_many :tickets, dependent: :restrict_with_exception
end
