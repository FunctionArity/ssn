class CreateChurches < ActiveRecord::Migration[8.1]
  def change
    create_table :churches do |t|
      t.string :name
      t.string :phone
      t.string :address
      t.references :priest, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
