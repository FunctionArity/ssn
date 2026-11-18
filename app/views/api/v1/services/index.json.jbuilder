if @filters.any?
  json.filters @filters
  json.results @results, partial: "api/v1/services/service", as: :service
  json.results_count @results_count
  json.page @page
  json.total_pages @total_pages
else
  json.current_guard do
    if @current_guard
      json.partial! "api/v1/guards/guard", guard: @current_guard
    else
      json.nil!
    end
  end
  json.services @services, partial: "api/v1/services/service", as: :service
  json.pending_other_services @pending_other_services do |service|
    json.partial! "api/v1/services/service", service: service
    json.guard_due_date service.guard.due_date
  end
end
