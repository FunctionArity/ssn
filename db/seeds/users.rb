require "csv"

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
