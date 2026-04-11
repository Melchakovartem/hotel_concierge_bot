module Admin
  class HotelTicketsController < BaseController
    before_action :set_hotel

    def index
      @tickets = @hotel.tickets
                     .joins(:guest, :department)
                     .left_outer_joins(:staff)
                     .where(guests: { hotel_id: @hotel.id }, departments: { hotel_id: @hotel.id })
                     .where("staffs.hotel_id = :hotel_id OR tickets.staff_id IS NULL", hotel_id: @hotel.id)
                     .includes(:guest, :department, :staff)
                     .order(created_at: :desc)
    end

    private

    def set_hotel
      @hotel = Hotel.find_by!(slug: params[:hotel_slug])
    rescue ActiveRecord::RecordNotFound
      render plain: "Not Found", status: :not_found
    end
  end
end
