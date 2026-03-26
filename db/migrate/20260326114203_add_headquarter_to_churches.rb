class AddHeadquarterToChurches < ActiveRecord::Migration[8.1]
  def up
    add_column :churches, :headquarter_id, :bigint

    execute <<-SQL
      UPDATE churches
      SET headquarter_id = (SELECT id FROM headquarters ORDER BY id DESC LIMIT 1)
    SQL

    change_column_null :churches, :headquarter_id, false
    add_index :churches, :headquarter_id
    add_foreign_key :churches, :headquarters
  end

  def down
    remove_foreign_key :churches, :headquarters
    remove_column :churches, :headquarter_id
  end
end
