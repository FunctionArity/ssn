# Empty is a normal service; urgent ones stand out in a stronger red.
class AddPriorityToServices < ActiveRecord::Migration[8.1]
  def change
    add_column :services, :priority, :integer
  end
end
