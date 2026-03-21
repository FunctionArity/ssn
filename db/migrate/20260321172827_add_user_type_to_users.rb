class AddUserTypeToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :user_type, :integer, default: 0, null: false
  end
end
