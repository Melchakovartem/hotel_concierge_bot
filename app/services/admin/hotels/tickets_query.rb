module Admin
  module Hotels
    class TicketsQuery < BaseService
      option :hotel

      def call
        hotel.tickets
             .joins(:guest, :department)
             .left_outer_joins(:staff)
             .where(guests: { hotel_id: hotel.id }, departments: { hotel_id: hotel.id })
             .where("staffs.hotel_id = :hotel_id OR tickets.staff_id IS NULL", hotel_id: hotel.id)
             .includes(:guest, :department, :staff)
             .order(created_at: :desc)
      end
    end
  end
end
