class CreateGuardSetups < ActiveRecord::Migration[8.1]
  def change
    create_table :guard_setups do |t|
      t.integer :day_number, null: false
      t.text :notes
      t.references :vocal, null: false, foreign_key: { to_table: :users }
      t.references :priest, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
