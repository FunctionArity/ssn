# Each sede has its own health facilities and churches. Those so far are the Mendoza sede's.
class AddHeadquarterToHealthFacilitiesAndChurches < ActiveRecord::Migration[8.1]
  TABLES = %i[health_facilities churches].freeze

  def up
    TABLES.each { |table| add_reference table, :headquarter, foreign_key: true }

    if TABLES.any? { |table| select_value("SELECT 1 FROM #{table} LIMIT 1") }
      mendoza_id = select_value("SELECT id FROM headquarters WHERE slug = 'mendoza'")
      raise "The Mendoza headquarter (slug 'mendoza') must exist to own the existing records" unless mendoza_id

      TABLES.each { |table| execute "UPDATE #{table} SET headquarter_id = #{Integer(mendoza_id)}" }
    end

    TABLES.each { |table| change_column_null table, :headquarter_id, false }
  end

  def down
    TABLES.each { |table| remove_reference table, :headquarter, foreign_key: true }
  end
end
