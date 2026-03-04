class AddHealthFacilityToServices < ActiveRecord::Migration[8.0]
  def change
    add_reference :services, :health_facility, null: true, foreign_key: true
  end
end
