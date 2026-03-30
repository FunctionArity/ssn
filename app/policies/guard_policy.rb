# frozen_string_literal: true

class GuardPolicy < ApplicationPolicy
  # create? checks that the current user is the vocal of the guard_setup this guard belongs to
  def create?
    is_admin? || (user.vocal? && record.guard_setup&.vocal == user)
  end

  def new?
    is_admin? || is_vocal?
  end

  def update?
    is_admin? || is_vocal?
  end

  def edit?
    is_admin? || is_vocal?
  end

  def close?
    is_admin? || is_vocal?
  end

  def destroy?
    is_admin? || is_vocal?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
