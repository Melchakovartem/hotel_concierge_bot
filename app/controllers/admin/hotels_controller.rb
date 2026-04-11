module Admin
  class HotelsController < BaseController
    before_action :set_hotel, only: %i[show edit update destroy]

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

    def edit; end

    def update
      result = Admin::Hotels::UpdateService.call(hotel: @hotel, params: hotel_params)
      @hotel = result.result

      if result.success?
        redirect_to admin_hotels_path, notice: "Hotel was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @hotel.destroy!

      redirect_to admin_hotels_path, notice: "Hotel was successfully deleted."
    rescue ActiveRecord::DeleteRestrictionError
      redirect_to admin_hotels_path, alert: "Hotel has associated records and cannot be deleted."
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
