class CreateContactDirectories < ActiveRecord::Migration[8.1]
  def change
    create_table :contact_directories do |t|
      t.references :headquarter, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :group_label
      t.date :updated_on
      t.integer :visibility, null: false, default: 0
      t.integer :position, null: false
      t.timestamps
    end

    create_table :contact_groups do |t|
      t.references :contact_directory, null: false, foreign_key: true
      t.string :name, null: false
      t.string :notes
      t.integer :position, null: false
      t.timestamps
    end

    create_table :contacts do |t|
      t.references :contact_group, null: false, foreign_key: true
      t.string :name, null: false
      t.string :detail
      t.string :phone
      t.string :email
      t.integer :position, null: false
      t.timestamps
    end
  end
end
