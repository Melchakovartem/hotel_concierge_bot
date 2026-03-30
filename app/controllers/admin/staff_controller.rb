module Admin
  class StaffController < BaseController
    def index
      @staff_members = Staff.includes(:hotel).order(:name)
    end
  end
end
