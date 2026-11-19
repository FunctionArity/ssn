# The privacy policy: what personal data the app keeps, what for, and how to see, correct or delete it. Public, so
# Google's OAuth consent screen (Sign in with Google) and anyone signing in can link to it.
class Doc::PrivacidadController < ApplicationController
  skip_before_action :authenticate_user!
  layout "doc"

  UPDATED_ON = Date.new(2026, 11, 19)
  # Where people ask to see, correct or delete their data.
  CONTACT_EMAIL = "info@serviciosacerdotalnocturno.org".freeze

  def index
  end
end
