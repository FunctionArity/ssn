class CreateHeadquarters < ActiveRecord::Migration[8.1]
  def change
    create_table :headquarters do |t|
      t.string :name
      t.references :president, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        Headquarter.new({ name: 'Mendoza', president: User.admin.first }).save
      end
    end
  end
end
