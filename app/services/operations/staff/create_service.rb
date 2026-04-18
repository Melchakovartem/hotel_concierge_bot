module Operations
  module Staff
    class CreateService < BaseService
      PERMITTED_ATTRIBUTES = %i[
        name
        email
        password
        password_confirmation
        department_id
      ].freeze

      option :manager
      option :params

      def call
        staff = ::Staff.new(permitted_params.merge(hotel: manager.hotel, role: :staff))

        if staff.save
          success(result: staff)
        else
          failure(error_code: :validation_failed, messages: staff.errors.full_messages, result: staff)
        end
      end

      private

      def permitted_params
        @permitted_params ||= raw_params(params).slice(*PERMITTED_ATTRIBUTES)
      end
    end
  end
end
