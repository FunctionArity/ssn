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
