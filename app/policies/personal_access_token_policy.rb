# frozen_string_literal: true

# Only super admins have API tokens, and each one manages their own, nobody else's.
class PersonalAccessTokenPolicy < ApplicationPolicy
  def index?
    super_admin?
  end

  def create?
    super_admin?
  end

  def destroy?
    super_admin? && record.user_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end
end
