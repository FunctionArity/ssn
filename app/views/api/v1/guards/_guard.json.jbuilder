json.extract! guard, :id, :number, :day_number, :due_date, :status, :notes
json.vocal { json.partial! "api/v1/user", user: guard.vocal }
json.priest { json.partial! "api/v1/user", user: guard.priest }
json.guardians guard.guardians, partial: "api/v1/user", as: :user
