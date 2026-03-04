class CreateHealthFacilities < ActiveRecord::Migration[8.0]
  def change
    create_table :health_facilities do |t|
      t.string :name, null: false
      t.string :address, null: false

      t.timestamps
    end
  end
end
