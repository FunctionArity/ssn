require "csv"

CSV.foreach(Rails.root.join("db/data/headquarters.csv"), headers: true, encoding: "bom|utf-8") do |row|
  begin
    Headquarter.find_or_create_by!(country: row["country"], state: row["state"], city: row["city"], address: row["address"]) do |headquarter|
      headquarter.phone       = row["phone"].presence
      headquarter.email       = row["email"].presence
      headquarter.whatsapp    = row["whatsapp"].presence
      headquarter.web_address = row["web_address"].presence
      headquarter.facebook    = row["facebook"].presence
      headquarter.instagram   = row["instagram"].presence
    end
  rescue ActiveRecord::RecordInvalid => e
    puts "Validation failed for Headquarter #{row["city"]}: #{e.record.errors.full_messages.join(', ')}"
  end
end

puts "Seeded #{Headquarter.count} headquarters from headquarters.csv"
