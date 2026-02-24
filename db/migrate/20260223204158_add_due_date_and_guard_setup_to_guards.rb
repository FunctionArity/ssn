class AddDueDateAndGuardSetupToGuards < ActiveRecord::Migration[8.1]
  def change
    add_column :guards, :due_date, :date, null: false, default: Date.today
    change_column_default :guards, :due_date, nil

    add_column :guards, :guard_setup_id, :bigint

    first_setup_id = execute("SELECT id FROM guard_setups ORDER BY id LIMIT 1").first&.fetch("id")
    execute("UPDATE guards SET guard_setup_id = #{first_setup_id}") if first_setup_id

    change_column_null :guards, :guard_setup_id, false
    add_index :guards, :guard_setup_id
    add_foreign_key :guards, :guard_setups
  end
end
