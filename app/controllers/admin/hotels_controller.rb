module Admin
  class HotelsController < BaseController
    before_action :set_hotel, only: :show

    def index
      @hotels = Hotel.order(:name)
    end

    def show; end

    def new
      @hotel = Hotel.new
    end

    def create
      result = Admin::Hotels::CreateService.call(params: hotel_params)
      @hotel = result.result

      if result.success?
        redirect_to admin_hotels_path, notice: "Hotel was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_hotel
      @hotel = Hotel.find_by!(slug: params[:slug])
    rescue ActiveRecord::RecordNotFound
      render plain: "Not Found", status: :not_found
    end

    def hotel_params
      params.require(:hotel).permit(:name, :timezone)
    end
  end
end
