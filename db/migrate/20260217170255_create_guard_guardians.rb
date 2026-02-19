class CreateGuardGuardians < ActiveRecord::Migration[8.1]
  def change
    create_table :guard_guardians do |t|
      t.references :guard, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :guard_guardians, [ :guard_id, :user_id ], unique: true
  end
end
