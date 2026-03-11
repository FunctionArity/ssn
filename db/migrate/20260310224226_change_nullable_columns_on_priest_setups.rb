class ChangeNullableColumnsOnPriestSetups < ActiveRecord::Migration[8.1]
  def change
    change_column_null :priest_setups, :day_of_week, true
    change_column_null :priest_setups, :week_number, true
  end
end
