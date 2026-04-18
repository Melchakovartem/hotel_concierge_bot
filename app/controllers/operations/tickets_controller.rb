module Operations
  class TicketsController < BaseController
    before_action :require_manager!, only: %i[edit update]
    before_action :require_staff!, only: %i[start complete]
    before_action :set_ticket, only: %i[show edit update start complete]

    def index
      @tickets = Operations::Tickets::VisibleTicketsQuery.call(staff: current_staff)
                                                        .page(params[:page])
                                                        .load
    end

    def show; end

    def edit
      prepare_ticket_form_options
    end

    def update
      result = Operations::Tickets::ManagerUpdateService.call(
        manager: current_staff,
        ticket: @ticket,
        params: ticket_params
      )

      handle_update_result(result)
    end

    def start
      transition_ticket(Operations::Tickets::StartService)
    end

    def complete
      transition_ticket(Operations::Tickets::CompleteService)
    end

    private

    def set_ticket
      @ticket = ticket_lookup_scope
                .preload(*ticket_associations)
                .find(params[:id])
    end

    def prepare_ticket_form_options
      @assignees = current_hotel.staff
                                .where(role: :staff)
                                .order(:name, :email)
                                .load
      @statuses = Ticket.statuses.keys
    end

    def ticket_lookup_scope
      return current_hotel.tickets if current_staff.manager?

      Operations::Tickets::VisibleTicketsQuery.call(
        staff: current_staff,
        preload_associations: false,
        ordered: false
      )
    end

    def ticket_associations
      associations = %i[department staff]
      associations << :guest if %w[update start complete].include?(action_name)
      associations
    end

    def ticket_params
      params.require(:ticket).permit(:staff_id, :status)
    end

    def transition_ticket(service)
      result = service.call(staff: current_staff, ticket: @ticket)

      handle_transition_result(result)
    end

    def handle_update_result(result)
      handle_result(result, on_failure: :edit) { prepare_ticket_form_options }
    end

    def handle_transition_result(result)
      handle_result(result, on_failure: :show)
    end

    def handle_result(result, on_failure:)
      @ticket = result.result

      if result.success?
        redirect_to operations_ticket_path(@ticket), notice: "Ticket updated"
      else
        @result = result
        yield if block_given?
        render on_failure, status: :unprocessable_entity
      end
    end
  end
end
