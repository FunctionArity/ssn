require "csv"

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
