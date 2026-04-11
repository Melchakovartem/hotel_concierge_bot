module Admin
  class HotelsController < BaseController
    before_action :set_hotel, only: :show

    def index
      @hotels = Hotel.order(:name)
    end

    def show; end

    private

    def set_hotel
      @hotel = Hotel.find_by!(slug: params[:slug])
    rescue ActiveRecord::RecordNotFound
      render plain: "Not Found", status: :not_found
    end
  end
end
