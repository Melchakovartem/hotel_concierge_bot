class Hotel < ApplicationRecord
  has_many :guests, dependent: :restrict_with_exception
  has_many :staff, dependent: :restrict_with_exception
  has_many :departments, dependent: :restrict_with_exception
  has_many :knowledge_base_articles, dependent: :restrict_with_exception
end
