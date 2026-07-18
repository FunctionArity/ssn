# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Each CSV file in db/data has a matching seed file in db/seeds. Files are loaded explicitly (not globbed) because
# db/seeds/services.rb is not part of db:seed — it is run manually with: DAY=<n> bundle exec rails runner db/seeds/services.rb

[
  "admin_user",
  "mendoza_health_facilities",
  "priest_users",
  "users",
  "churches",
  "headquarters"
].each do |seed|
  load Rails.root.join("db/seeds", "#{seed}.rb")
end
