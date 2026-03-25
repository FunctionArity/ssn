require "csv"

class SeedUsersFromRelevamientoGuardianes < ActiveRecord::Migration[8.1]
  CSV_PATH = Rails.root.join("db", "data", "relevamiento_guardianes.csv")

  def up
    # Delete all data in dependency order
    execute "DELETE FROM services"
    execute "DELETE FROM guard_guardians"
    execute "DELETE FROM guards"
    execute "DELETE FROM guard_setup_guardians"
    execute "DELETE FROM guard_setups"
    execute "DELETE FROM priest_setups"
    execute "DELETE FROM active_storage_attachments"
    execute "DELETE FROM active_storage_blobs"
    execute "DELETE FROM users WHERE role != 2"

    # Import users from CSV
    CSV.foreach(CSV_PATH, headers: true, encoding: "UTF-8") do |row|
      first_name = row["first_name"]&.strip&.split&.map(&:capitalize)&.join(" ")
      last_name  = row["last_name"]&.strip&.split&.map(&:capitalize)&.join(" ")
      next if first_name.blank? || last_name.blank?

      raw_email = row["email"]&.strip
      email = (raw_email&.include?("@") ? raw_email : nil) || "#{row['dni']&.strip&.gsub(/\D/, "")}@placeholder.local"
      dni   = row["dni"]&.strip&.gsub(/\D/, "").presence&.to_i

      execute <<~SQL
        INSERT INTO users (
          first_name, last_name, email, phone, dni, address, city,
          date_of_birth, start_day, role, user_type,
          encrypted_password, created_at, updated_at
        ) VALUES (
          #{quote(first_name)},
          #{quote(last_name)},
          #{quote(email)},
          #{quote(row["phone"]&.strip)},
          #{quote_or_null(dni)},
          #{quote(row["address"]&.strip)},
          #{quote(row["departamento"]&.strip)},
          #{quote_or_null(parse_date(row["date_of_birth"]))},
          #{quote_or_null(parse_date(row["start_day"]))},
          0,
          0,
          #{quote(placeholder_password)},
          NOW(), NOW()
        )
        ON CONFLICT (email) DO NOTHING
      SQL
    end

    say "Imported #{count_users} users from #{CSV_PATH.basename}"
    User.find_by(email: 'pablorodriguez.ar@gmail.com').update(user_type: :super_admin)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def parse_date(str)
    return nil if str.blank?
    Date.strptime(str.strip, "%d/%m/%Y")
  rescue Date::Error
    nil
  end

  def quote(value)
    value.present? ? ActiveRecord::Base.connection.quote(value.to_s) : "NULL"
  end

  def quote_or_null(value)
    value.nil? ? "NULL" : ActiveRecord::Base.connection.quote(value)
  end

  def placeholder_password
    ::BCrypt::Password.create('password123')
  end

  def count_users
    ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM users").to_i
  end
end
