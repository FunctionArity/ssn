# The JSON API the React front end uses. Requests carry "Authorization: Bearer <token>" (see ApiToken) instead of the
# Devise session, and see the data of the user's sede, like the HTML app. Super admins work in another sede by sending
# its id in the X-Headquarter-Id header, the API's take on CurrentHeadquartersController.
module Api
  module V1
    class BaseController < ActionController::API
      include AbstractController::Translation
      include Pundit::Authorization

      set_current_tenant_through_filter

      before_action :authenticate_api_user!
      before_action :set_current_headquarter

      rescue_from Pundit::NotAuthorizedError, with: :forbidden
      rescue_from ActiveRecord::RecordNotFound, with: :not_found

      attr_reader :current_user, :api_token
      helper_method :current_user, :current_headquarter

      private

      def authenticate_api_user!
        @api_token = request.authorization.to_s[/\ABearer (.+)\z/, 1]
        @current_user = ApiToken.user_for(api_token)
        render_error(t("devise.failure.unauthenticated"), :unauthorized) unless @current_user
      end

      def current_headquarter
        @current_headquarter ||= (switched_headquarter if current_user.super_admin?) || current_user.headquarter
      end

      def switched_headquarter
        id = request.headers["X-Headquarter-Id"]
        Headquarter.find_by(id: id) if id.present?
      end

      def set_current_headquarter
        set_current_tenant(current_headquarter)
      end

      def render_error(message, status)
        render json: { error: message }, status: status
      end

      def forbidden
        render_error(t("pundit.not_authorized"), :forbidden)
      end

      def not_found
        render_error(t("api.errors.not_found"), :not_found)
      end
    end
  end
end
