# Loads the contact directories transcribed in db/seeds/contact_directories.rb (e.g. Mendoza's
# "Referentes Pastoral de la Salud"). The seed skips directories that already exist, so this is safe to run
# where they were created by hand. New databases get the same data from bin/rails db:seed.
class SeedContactDirectories < ActiveRecord::Migration[8.1]
  def up
    load Rails.root.join("db/seeds/contact_directories.rb")
  end

  def down
    # Data only: directories may have been edited in the app since, so they are not removed automatically.
  end
end
