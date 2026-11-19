module Api
  module V1
    class GuardsController < BaseController
      PER_PAGE = 20

      # Unlike the HTML list, reading the list doesn't create today's guard from its setup.
      def index
        guards = Guard.order(due_date: :desc, id: :desc)
        @total_pages = [ (guards.count / PER_PAGE.to_f).ceil, 1 ].max
        @page = params[:page].to_i.clamp(1, @total_pages)
        @guards = guards.includes(:vocal, :priest, :guardians).limit(PER_PAGE).offset((@page - 1) * PER_PAGE).to_a
        @services_count_by_guard = Service.where(guard: @guards).group(:guard_id).count
        unless @guards.any? { |g| g.due_date == Date.current }
          @today_guard_setup = GuardSetup.includes(:vocal, :guardians).find_by(day_number: Date.current.day)
        end
      end

      def show
        @guard = Guard.includes(:vocal, :priest, :guardians).find(params.expect(:id))
        @services = @guard.services.includes(:created_by, :health_facility).order(:position)
      end
    end
  end
end
