# frozen_string_literal: true

class HealthFacilityPolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    is_admin?
  end

  def new?
    create?
  end

  def update?
    is_admin?
  end

  def edit?
    update?
  end

  def destroy?
    is_admin?
  end

  def show?
    true
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  private

  def is_admin?
    super_admin? || admin?
  end
end
