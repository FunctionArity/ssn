# The sedes, for super admins to pick the one they work in.
module Api
  module V1
    class HeadquartersController < BaseController
      def index
        authorize Headquarter
        @headquarters = Headquarter.order(:country, :city)
      end
    end
  end
end
