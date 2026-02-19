class RenameDayToDayNumberInGuards < ActiveRecord::Migration[8.1]
  def change
    remove_column :guards, :day, :date, null: false
    add_column :guards, :day_number, :integer, default: 0, null: false
    change_column_default :guards, :day_number, from: 0, to: nil
  end
end
