# Signs in to the API with email and password, or with the ID token Google One Tap gives the page, and returns a
# token for the following requests. Same rules as the HTML sign-in: locked users and pending invitations can't.
# Signing out revokes the token it's called with.
module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate_api_user!, :set_current_headquarter, only: %i[ create google ]
      rate_limit to: 10, within: 1.minute, only: %i[ create google ],
                 with: -> { render_error(t("api.errors.too_many_attempts"), :too_many_requests) }

      def create
        user = User.in_any_sede.find_by(email: params[:email].to_s.strip.downcase)

        if user&.valid_for_authentication? { user.valid_password?(params[:password].to_s) }
          sign_in_with(user)
        else
          failure = user&.unauthenticated_message == :locked ? :locked : :invalid
          render_error(t("devise.failure.#{failure}", authentication_keys: "Email"), :unauthorized)
        end
      end

      def google
        claims = GoogleIdToken.verify(params[:credential])
        user = User.from_google_id_token(claims) if claims

        if user
          sign_in_with(user)
        else
          render_error(t(claims ? "devise.omniauth_callbacks.no_account" : "devise.omniauth_callbacks.google_failure"), :unauthorized)
        end
      end

      def destroy
        ApiToken.revoke(api_token)
        head :no_content
      end

      private

      def sign_in_with(user)
        unless user.active_for_authentication?
          return render_error(t("devise.failure.#{user.inactive_message}", authentication_keys: "Email"), :unauthorized)
        end

        user.update_tracked_fields!(request)
        @current_user = user
        @token = ApiToken.issue(user)
        render "api/v1/me/show", status: :created
      end
    end
  end
end
