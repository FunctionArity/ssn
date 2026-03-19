# frozen_string_literal: true

class GuardPolicy < ApplicationPolicy
  # create? checks that the current user is the vocal of the guard_setup this guard belongs to
  def create?
    user.vocal? && record.guard_setup&.vocal == user
  end

  def new?
    create?
  end

  def update?
    user.vocal? && (record.vocal == user || record.guardians.include?(user))
  end

  def edit?
    update?
  end

  def destroy?
    user.vocal? && record.vocal == user
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
