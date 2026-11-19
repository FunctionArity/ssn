# The terms of use: who may use the app, what for, and how to treat the data in it. Public, so Google's OAuth consent
# screen (Sign in with Google) and anyone signing in can link to it.
class Doc::TerminosController < ApplicationController
  skip_before_action :authenticate_user!
  layout "doc"

  UPDATED_ON = Date.new(2026, 11, 19)
end
