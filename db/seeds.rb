# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

User.find_or_create_by!(email: "alice@example.com") do |user|
  user.first_name = "Alice"
  user.last_name = "Johnson"
  user.password = "password123"
  user.password_confirmation = "password123"
end

User.find_or_create_by!(email: "bob@example.com") do |user|
  user.first_name = "Bob"
  user.last_name = "Smith"
  user.password = "password123"
  user.password_confirmation = "password123"
end

puts "Seeded 2 users:"
puts "  alice@example.com / password123"
puts "  bob@example.com   / password123"

require "csv"

csv_path = Rails.root.join("db", "mendoza_health_facilities.csv")
count = 0

CSV.foreach(csv_path, headers: true) do |row|
  HealthFacility.find_or_create_by!(name: row["name"]) do |facility|
    facility.address = row["full_address"]
  end
  count += 1
end

puts "Seeded #{count} health facilities from mendoza_health_facilities.csv"
