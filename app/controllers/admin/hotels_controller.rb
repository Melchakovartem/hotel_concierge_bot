module Admin
  class HotelsController < BaseController
    def index
      @hotels = Hotel.order(:name)
    end
  end
end
