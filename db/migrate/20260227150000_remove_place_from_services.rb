class RemovePlaceFromServices < ActiveRecord::Migration[8.0]
  def change
    remove_column :services, :place, :integer
  end
end
