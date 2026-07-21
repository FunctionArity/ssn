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
