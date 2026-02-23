class GuardSetupGuardian < ApplicationRecord
  belongs_to :guard_setup
  belongs_to :user
end
