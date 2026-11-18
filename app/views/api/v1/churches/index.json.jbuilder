json.churches @churches do |church|
  json.extract! church, :id, :name, :phone, :address
end
