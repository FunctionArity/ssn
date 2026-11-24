class ApplicationController < ActionController::Base
  impersonates :user, with: ->(id) { User.find_by(id: id) }

  include Pundit::Authorization

  # The language comes from ?locale=es|en and is remembered in a cookie, so it outlasts signing out; Spanish
  # otherwise. Prepended so Devise's messages and everything after it use it too.
  prepend_around_action :switch_locale

  set_current_tenant_through_filter

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :set_current_headquarter
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_paper_trail_whodunnit

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :acting_as_self?, :current_headquarter

  protected

  # True unless an admin is impersonating someone, e.g. to skip changes only the real user should make.
  def acting_as_self?
    current_user == true_user
  end

  # The sede whose data the user works with: their own, or the one a super admin switched to. Impersonating someone
  # shows their sede. Nobody signed in, nobody's sede: public pages see every sede.
  def current_headquarter
    return unless current_user

    @current_headquarter ||= (switched_headquarter if acting_as_self? && current_user.super_admin?) || current_user.headquarter
  end

  def set_current_headquarter
    set_current_tenant(current_headquarter)
  end

  def switched_headquarter
    Headquarter.find_by(id: session[:headquarter_id]) if session[:headquarter_id]
  end

  def switch_locale(&)
    cookies[:locale] = { value: params[:locale], expires: 1.year } if available_locale?(params[:locale])
    I18n.with_locale(available_locale?(cookies[:locale]) ? cookies[:locale] : I18n.default_locale, &)
  end

  def available_locale?(locale)
    locale.to_s.in?(I18n.available_locales.map(&:to_s))
  end

  # Record the real user behind a change, even while impersonating someone else.
  def user_for_paper_trail
    true_user&.id
  end

  def user_not_authorized
    redirect_to root_path, alert: t("pundit.not_authorized")
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:invite, keys: [ :first_name, :last_name, :role, :phone, :church_id ])
    devise_parameter_sanitizer.permit(:accept_invitation, keys: [ :first_name, :last_name ])
  end
end
