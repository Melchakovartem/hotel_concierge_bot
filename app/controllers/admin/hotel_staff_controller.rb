module Admin
  class HotelStaffController < BaseController
    before_action :set_hotel

    def index
      @staff = @hotel.staff.order(:name)
    end

    def show
      @staff_member = @hotel.staff.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render plain: "Not Found", status: :not_found
    end

    private

    def set_hotel
      @hotel = Hotel.find_by!(slug: params[:hotel_slug])
    rescue ActiveRecord::RecordNotFound
      render plain: "Not Found", status: :not_found
    end
  end
end
