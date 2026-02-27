class RemovePriestIdFromGuardSetups < ActiveRecord::Migration[8.1]
  def change
    remove_column :guard_setups, :priest_id, :bigint
  end
end
