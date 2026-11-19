# Today's setup is there only when today has no guard yet and a setup exists for today's day of the month.
if @today_guard_setup
  json.today_guard_setup do
    json.partial! "api/v1/guard_setups/guard_setup", guard_setup: @today_guard_setup
  end
else
  json.today_guard_setup nil
end
json.guards @guards do |guard|
  json.partial! "api/v1/guards/guard", guard: guard
  json.services_count @services_count_by_guard.fetch(guard.id, 0)
end
json.page @page
json.total_pages @total_pages
