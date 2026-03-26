class AddHeadquarterToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :headquarter, null: true, foreign_key: true

    reversible do |dir|
      dir.up do
        first_id = execute("SELECT id FROM headquarters ORDER BY id LIMIT 1").first&.fetch("id")
        execute("UPDATE users SET headquarter_id = #{first_id}") if first_id
      end
    end

    change_column_null :users, :headquarter_id, false
  end
end
