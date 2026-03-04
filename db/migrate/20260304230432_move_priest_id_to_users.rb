class MovePriestIdToUsers < ActiveRecord::Migration[8.1]
  def change
    remove_reference :churches, :priest, foreign_key: { to_table: :users }, index: true
    add_reference :users, :church, foreign_key: true, null: true, index: true
  end
end
