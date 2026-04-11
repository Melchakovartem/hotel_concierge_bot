module Admin
  class HotelTicketsController < BaseController
    before_action :set_hotel

    def index
      @tickets = @hotel.tickets.includes(:guest, :department, :staff).order(created_at: :desc)
    end

    private

    def set_hotel
      @hotel = Hotel.find_by!(slug: params[:hotel_slug])
    rescue ActiveRecord::RecordNotFound
      render plain: "Not Found", status: :not_found
    end
  end
end
