class Ticket < ApplicationRecord
  belongs_to :guest
  belongs_to :department
  belongs_to :staff, optional: true

  enum :status, {
    new: 0,
    in_progress: 1,
    done: 2,
    canceled: 3
  }, scopes: false

  enum :priority, {
    low: 0,
    medium: 1,
    high: 2
  }, scopes: false
end
