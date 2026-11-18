json.health_facilities @health_facilities do |health_facility|
  json.extract! health_facility, :id, :name, :address
end
