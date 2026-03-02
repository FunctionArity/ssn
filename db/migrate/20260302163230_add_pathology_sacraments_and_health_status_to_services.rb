class AddPathologySacramentsAndHealthStatusToServices < ActiveRecord::Migration[8.1]
  def change
    add_column :services, :pathology, :string
    add_column :services, :sacraments, :string
    add_column :services, :health_status, :string
  end
end
