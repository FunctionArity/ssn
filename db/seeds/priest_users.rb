require "csv"

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
