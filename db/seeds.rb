# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

begin
  User.find_or_create_by!(email: "pablorodriguez.ar@gmail.com") do |user|
    user.first_name = "Pablo"
    user.last_name = "Rodriguez"
    user.role = "guardian"
    user.password = "password123"
    user.password_confirmation = "password123"
  end
rescue ActiveRecord::RecordInvalid => e
  puts "Validation failed for User: #{e.record.errors.full_messages.join(', ')}"
end

require "csv"

csv_path = Rails.root.join("db/data", "mendoza_health_facilities.csv")
count = 0

CSV.foreach(csv_path, headers: true) do |row|
  begin
    HealthFacility.find_or_create_by!(name: row["name"]) do |facility|
      facility.address = row["full_address"]
    end
    count += 1
  rescue ActiveRecord::RecordInvalid => e
    puts "Validation failed for HealthFacility #{row["name"]}: #{e.record.errors.full_messages.join(', ')}"
  end
end

puts "Seeded #{count} health facilities from mendoza_health_facilities.csv"

CSV.foreach(Rails.root.join("db/data/priest_users.csv"), headers: true) do |row|
  next if row["first_name"].blank? || row["last_name"].blank?

  email = "#{row["first_name"].split(' ').join('.')}.#{row["last_name"]}@gmail.com".downcase
  begin
    User.find_or_create_by!(email: email) do |user|
      user.first_name = row["first_name"]
      user.last_name  = row["last_name"]
      user.password   = 'password123'
      user.role       = 'priest'
      user.phone      = row["phone"]
    end
  rescue ActiveRecord::RecordInvalid => e
    puts "Validation failed for Priest User #{email}: #{e.record.errors.full_messages.join(', ')}"
  end
end

puts "Seeded #{User.priests.count} priest users from priest_users.csv"

CSV.foreach(Rails.root.join("db/data/users.csv"), headers: true) do |row|
  begin
    User.find_or_create_by!(email: row["email"]) do |user|
      user.first_name = row["first_name"]
      user.last_name  = row["last_name"]
      user.password   = 'password123'
      user.role       = row["role"]
    end
  rescue ActiveRecord::RecordInvalid => e
    puts "Validation failed for User #{row["email"]}: #{e.record.errors.full_messages.join(', ')}"
  end
end

puts "Seeded #{User.vocals.count + User.guardians.count} users from users.csv"

CSV.foreach(Rails.root.join("db/data/churches.csv"), headers: true) do |row|
  begin
    Church.find_or_create_by!(name: row["name"]) do |church|
      church.phone   = row["phone"].presence
      church.address = row["address"]
    end
  rescue ActiveRecord::RecordInvalid => e
    puts "Validation failed for Church #{row["name"]}: #{e.record.errors.full_messages.join(', ')}"
  end
end

puts "Seeded #{Church.count} churches from churches.csv"
