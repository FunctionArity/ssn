# frozen_string_literal: true

class ServicePolicy < ApplicationPolicy
  def create?
    super_admin? || member_of_guard?
  end

  def update?
    create?
  end

  def edit?
    create?
  end

  def new?
    create?
  end

  def destroy?
    create?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  private

  def member_of_guard?
    guard = record.guard
    return false unless guard

    guard.vocal == user || guard.guardians.include?(user)
  end

end
