class CreateGuardSetupGuardians < ActiveRecord::Migration[8.1]
  def change
    create_table :guard_setup_guardians do |t|
      t.references :guard_setup, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
    add_index :guard_setup_guardians, [:guard_setup_id, :user_id], unique: true
  end
end
