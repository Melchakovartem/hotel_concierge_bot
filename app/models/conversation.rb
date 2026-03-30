class Conversation < ApplicationRecord
  belongs_to :guest

  has_many :messages, dependent: :restrict_with_exception

  enum :status, {
    open: 0,
    waiting_for_staff: 1,
    waiting_for_guest: 2,
    closed: 3
  }, scopes: false
end
