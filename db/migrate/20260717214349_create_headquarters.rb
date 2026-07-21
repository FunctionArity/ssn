class CreateHeadquarters < ActiveRecord::Migration[8.1]
  def change
    create_table :headquarters do |t|
      t.string :country, null: false
      t.string :state, null: false
      t.string :city, null: false
      t.string :address, null: false
      t.string :phone
      t.string :email
      t.string :whatsapp
      t.string :web_address
      t.string :facebook
      t.string :instagram

      t.timestamps
    end
  end
end
