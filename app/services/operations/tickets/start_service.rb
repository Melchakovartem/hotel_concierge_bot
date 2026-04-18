module Operations
  module Tickets
    class StartService < TicketTransitionService
      private

      def target_status = :in_progress
      def valid_source_status? = ticket.new?
      def transition_error_message = "Ticket cannot be started"
    end
  end
end
