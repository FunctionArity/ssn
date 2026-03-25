class AddNroToServices < ActiveRecord::Migration[8.1]
  def change
    add_column :services, :nro, :bigint
  end
end
