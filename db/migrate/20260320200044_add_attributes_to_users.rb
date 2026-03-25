class AddAttributesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :date_of_birth, :date
    add_column :users, :dni, :integer
    add_column :users, :address, :string
    add_column :users, :city, :string
    add_column :users, :start_day, :date
  end
end
