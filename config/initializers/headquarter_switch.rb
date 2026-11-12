# A super admin's switched sede (see CurrentHeadquartersController) lasts until they sign out. Signing in starts over in
# the user's own sede, even when the previous session expired instead of signing out.
Warden::Manager.after_set_user except: :fetch do |_user, auth, _opts|
  auth.raw_session.delete("headquarter_id")
end
