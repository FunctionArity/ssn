module Api
  module V1
    # Today's open guard and its services, the pending services of other guards, or a search, like the HTML list.
    class ServicesController < BaseController
      SEARCH_FILTERS = ::ServicesController::SEARCH_FILTERS
      PER_PAGE = ::ServicesController::RESULTS_PER_PAGE

      def index
        @filters = params.permit(*SEARCH_FILTERS).to_h.transform_values(&:strip).compact_blank

        if @filters.any?
          set_search_results
        else
          @current_guard = Guard.includes(:vocal, :priest, :guardians).find_by(status: :open, due_date: Date.current)
          @services = @current_guard ? @current_guard.services.includes(:created_by, :health_facility).order(:position) : Service.none
          @pending_other_services = Service.pending
                                           .includes(:guard, :created_by, :health_facility)
                                           .where.not(guard: @current_guard)
                                           .joins(:guard)
                                           .order("guards.due_date DESC", :position)
        end
      end

      def show
        @service = Service.includes(:guard, :created_by, :health_facility).find(params.expect(:id))
      end

      private

      def set_search_results
        results = Service.search(@filters)
        @results_count = results.count
        @total_pages = [ (@results_count / PER_PAGE.to_f).ceil, 1 ].max
        @page = params[:page].to_i.clamp(1, @total_pages)
        @results = results.includes(:guard, :created_by, :health_facility)
                          .order(due_date: :desc, id: :desc)
                          .limit(PER_PAGE)
                          .offset((@page - 1) * PER_PAGE)
      end
    end
  end
end
