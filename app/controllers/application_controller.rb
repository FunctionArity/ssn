class ApplicationController < ActionController::Base
  impersonates :user, with: ->(id) { User.find_by(id: id) }

  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def user_not_authorized
    redirect_to root_path, alert: t("pundit.not_authorized")
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:invite, keys: [ :first_name, :last_name, :role, :phone, :church_id ])
    devise_parameter_sanitizer.permit(:accept_invitation, keys: [ :first_name, :last_name ])
  end
end
