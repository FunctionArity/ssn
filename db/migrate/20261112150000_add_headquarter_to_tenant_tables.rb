# Users, guard setups, guards, services and priest setups belong to a sede. Everything so far is the Mendoza sede's.
class AddHeadquarterToTenantTables < ActiveRecord::Migration[8.1]
  TABLES = %i[users guard_setups guards services priest_setups].freeze

  def up
    TABLES.each { |table| add_reference table, :headquarter, foreign_key: true }

    if TABLES.any? { |table| select_value("SELECT 1 FROM #{table} LIMIT 1") }
      mendoza_id = select_value("SELECT id FROM headquarters WHERE slug = 'mendoza'")
      raise "The Mendoza headquarter (slug 'mendoza') must exist to own the existing records" unless mendoza_id

      TABLES.each { |table| execute "UPDATE #{table} SET headquarter_id = #{Integer(mendoza_id)}" }
    end

    TABLES.each { |table| change_column_null table, :headquarter_id, false }

    # Each sede has its own priest schedule.
    remove_index :priest_setups, %i[week_number day_of_week]
    add_index :priest_setups, %i[headquarter_id week_number day_of_week], unique: true, name: "index_priest_setups_on_headquarter_week_and_day"
  end

  def down
    remove_index :priest_setups, name: "index_priest_setups_on_headquarter_week_and_day"
    add_index :priest_setups, %i[week_number day_of_week], unique: true

    TABLES.each { |table| remove_reference table, :headquarter, foreign_key: true }
  end
end
