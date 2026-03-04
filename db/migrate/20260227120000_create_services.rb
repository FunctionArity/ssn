class CreateServices < ActiveRecord::Migration[8.0]
  def change
    create_table :services do |t|
      t.references :guard, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.date :due_date, null: false
      t.string :full_name, null: false
      t.integer :age
      t.integer :status, default: 0, null: false
      t.string :caller_full_name
      t.string :caller_phone
      t.string :caller_relationship
      t.text :comments
      t.string :address
      t.integer :place

      t.timestamps
    end
  end
end
