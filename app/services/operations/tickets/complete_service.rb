module Operations
  module Tickets
    class CompleteService < TicketTransitionService
      private

      def target_status = :done
      def valid_source_status? = ticket.in_progress?
      def transition_error_message = "Ticket cannot be completed"
    end
  end
end
