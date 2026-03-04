class AddHealthFacilityPlace < ActiveRecord::Migration[8.1]
  def change
    add_column :services, :health_facility_place, :string
  end
end
