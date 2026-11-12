# Each sede (Headquarter) only sees its own users, guard setups, guards, services and priest setups: the controllers set
# the signed-in user's sede as the current tenant. A tenant isn't required, because Devise loads the user before it's
# known, and the console, seeds and migrations work across sedes.
ActsAsTenant.configure do |config|
  config.require_tenant = false
end
