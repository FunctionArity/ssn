class AddPositionToServices < ActiveRecord::Migration[8.1]
  def up
    add_column :services, :position, :integer

    execute <<~SQL
      WITH ordered AS (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY guard_id ORDER BY due_date DESC, created_at DESC) AS rn
        FROM services
      )
      UPDATE services SET position = ordered.rn
      FROM ordered
      WHERE services.id = ordered.id
    SQL

    change_column_null :services, :position, false
    add_index :services, [ :guard_id, :position ]
  end

  def down
    remove_column :services, :position
  end
end
