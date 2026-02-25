class CreatePriestSetups < ActiveRecord::Migration[8.0]
  def change
    create_table :priest_setups do |t|
      t.references :priest, null: false, foreign_key: { to_table: :users }
      t.integer :week_number, null: false
      t.integer :day_of_week, null: false

      t.timestamps
    end

    add_index :priest_setups, [ :week_number, :day_of_week ], unique: true
  end
end
