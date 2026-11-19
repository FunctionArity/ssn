json.guard do
  json.partial! "api/v1/guards/guard", guard: @guard
  json.services @services, partial: "api/v1/services/service", as: :service
end
