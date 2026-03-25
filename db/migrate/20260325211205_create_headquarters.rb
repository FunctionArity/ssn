class CreateHeadquarters < ActiveRecord::Migration[8.1]
  def change
    create_table :headquarters do |t|
      t.string :name
      t.references :president, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
