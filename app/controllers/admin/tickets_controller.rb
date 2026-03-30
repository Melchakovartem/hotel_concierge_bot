module Admin
  class TicketsController < BaseController
    def index
      @tickets = Ticket.includes(:guest, :department, :staff).order(created_at: :desc)
    end
  end
end
