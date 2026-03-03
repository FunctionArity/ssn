class AddStatusToGuards < ActiveRecord::Migration[8.1]
  def change
    add_column :guards, :status, :integer, default: 0, null: false
  end
end
