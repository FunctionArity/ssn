class AddHeadquarterToHealthFacilities < ActiveRecord::Migration[8.1]
  def up
    add_column :health_facilities, :headquarter_id, :bigint

    execute <<-SQL
      UPDATE health_facilities
      SET headquarter_id = (SELECT id FROM headquarters ORDER BY id DESC LIMIT 1)
    SQL

    change_column_null :health_facilities, :headquarter_id, false
    add_index :health_facilities, :headquarter_id
    add_foreign_key :health_facilities, :headquarters
  end

  def down
    remove_foreign_key :health_facilities, :headquarters
    remove_column :health_facilities, :headquarter_id
  end
end
