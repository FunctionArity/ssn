# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

User.find_or_create_by!(email: "pablorodriguez.ar@gmail.com") do |user|
  user.first_name = "Pablo"
  user.last_name = "Rodriguez"
  user.role = "guardian"
  user.password = "password123"
  user.password_confirmation = "password123"
end

require "csv"

csv_path = Rails.root.join("db/data", "mendoza_health_facilities.csv")
count = 0

CSV.foreach(csv_path, headers: true) do |row|
  HealthFacility.find_or_create_by!(name: row["name"]) do |facility|
    facility.address = row["full_address"]
  end
  count += 1
end

puts "Seeded #{count} health facilities from mendoza_health_facilities.csv"

CSV.foreach(Rails.root.join("db/data/guardian_users.csv"), headers: true) do |row|
  User.find_or_create_by!(email: row["email"]) do |user|
    user.first_name = row["first_name"]
    user.last_name  = row["last_name"]
    user.password   = row["password"]
    user.role       = row["role"]
    user.phone      = row["phone"]
  end
end

puts "Seeded 30 guardian users from guardian_users.csv"

CSV.foreach(Rails.root.join("db/data/priest_users.csv"), headers: true) do |row|
  User.find_or_create_by!(email: row["email"]) do |user|
    user.first_name = row["first_name"]
    user.last_name  = row["last_name"]
    user.password   = row["password"]
    user.role       = row["role"]
    user.phone      = row["phone"]
  end
end

puts "Seeded 30 priest users from priest_users.csv"

CSV.foreach(Rails.root.join("db/data/vocal_users.csv"), headers: true) do |row|
  User.find_or_create_by!(email: row["email"]) do |user|
    user.first_name = row["first_name"]
    user.last_name  = row["last_name"]
    user.password   = row["password"]
    user.role       = row["role"]
    user.phone      = row["phone"]
  end
end

puts "Seeded 30 vocal users from vocal_users.csv"
