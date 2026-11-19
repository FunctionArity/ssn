json.service do
  json.partial! "api/v1/services/service", service: @service
  json.extract! @service, :address, :caller_full_name, :caller_phone, :caller_relationship, :health_status,
                :sacraments, :note, :created_at, :updated_at
  json.comments_count @service.comments.size
  json.guard @service.guard.slice(:id, :day_number, :due_date, :status)
end
