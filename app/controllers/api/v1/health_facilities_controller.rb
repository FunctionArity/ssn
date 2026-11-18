module Api
  module V1
    class HealthFacilitiesController < BaseController
      # Like the HTML list, the name filter starts at 3 characters.
      def index
        authorize HealthFacility
        query = params[:q].to_s.strip
        scope = query.length >= 3 ? HealthFacility.search_by_name(query) : HealthFacility.all
        @health_facilities = scope.order(:name)
      end
    end
  end
end
