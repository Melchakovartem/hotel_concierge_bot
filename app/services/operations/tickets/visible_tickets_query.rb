module Operations
  module Tickets
    class VisibleTicketsQuery
      def self.call(staff:, preload_associations: true, ordered: true)
        new(staff, preload_associations: preload_associations, ordered: ordered).call
      end

      def initialize(staff, preload_associations:, ordered:)
        @staff = staff
        @preload_associations = preload_associations
        @ordered = ordered
      end

      def call
        return Ticket.none if staff.admin?
        return base_scope if staff.manager?

        base_scope.where(staff_id: staff.id)
                  .or(base_scope.where(department_id: staff.department_id))
      end

      private

      attr_reader :staff, :preload_associations, :ordered

      def base_scope
        scope = staff.hotel.tickets
        scope = scope.preload(:department, :staff) if preload_associations
        scope = scope.order(created_at: :desc, id: :desc) if ordered
        scope
      end
    end
  end
end
