json.extract! service, :id, :guard_id, :position, :full_name, :age, :due_date, :status, :priority,
              :health_facility_place, :pathology
json.health_facility service.health_facility&.slice(:id, :name)
json.created_by { json.partial! "api/v1/user", user: service.created_by }
