json.guards @guard_setups do |guard_setup|
  json.partial! "api/v1/guard_setups/guard_setup", guard_setup: guard_setup
end
