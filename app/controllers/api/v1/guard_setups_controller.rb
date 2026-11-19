module Api
  module V1
    class GuardSetupsController < BaseController
      # Unlike the HTML list, reading the list doesn't create today's guard from its setup.
      def index
        @guard_setups = GuardSetup.includes(:vocal, :guardians).order(:day_number)
      end

      def show
        @guard_setup = GuardSetup.find(params.expect(:id))
      end
    end
  end
end
