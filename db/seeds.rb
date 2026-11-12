# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Each CSV file in db/data has a matching seed file in db/seeds. Files are loaded explicitly (not globbed) because
# db/seeds/services.rb is not part of db:seed — it is run manually with: bundle exec rails runner db/seeds/services.rb
# (defaults to today's day of month; pass DAY=<n> to target a different guard)

load_seed = ->(seed) { load Rails.root.join("db/seeds", "#{seed}.rb") }

# Shared by every sede.
%w[headquarters mendoza_health_facilities churches contact_directories].each(&load_seed)

# The users so far are the Mendoza sede's.
ActsAsTenant.with_tenant(Headquarter.friendly.find("mendoza")) do
  %w[admin_user priest_users users].each(&load_seed)
end
