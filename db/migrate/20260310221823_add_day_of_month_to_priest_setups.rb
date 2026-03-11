class AddDayOfMonthToPriestSetups < ActiveRecord::Migration[8.1]
  def change
    add_column :priest_setups, :day_of_month, :integer
  end
end
