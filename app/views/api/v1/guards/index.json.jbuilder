json.today_guard_setup do
  json.partial! "api/v1/guard_setups/guard_setup", guard_setup: @today_guard_setup
end
json.guards @guards do |guard|
  json.partial! "api/v1/guards/guard", guard: guard
  json.services_count @services_count_by_guard.fetch(guard.id, 0)
end
json.page @page
json.total_pages @total_pages
