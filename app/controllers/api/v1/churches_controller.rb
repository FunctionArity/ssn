module Api
  module V1
    class ChurchesController < BaseController
      def index
        authorize Church
        @churches = Church.order(:name)
      end
    end
  end
end
