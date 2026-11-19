json.extract! guard_setup, :id, :day_number, :due_date, :notes
json.vocal { json.partial! "api/v1/user", user: guard_setup.vocal }
json.guardians guard_setup.guardians, partial: "api/v1/user", as: :user
