# frozen_string_literal: true

class HeadquarterPolicy < ApplicationPolicy
  def index?
    true
  end

  # Sedes are added and removed by super admins: a sede can only be deleted once nobody works there.
  def create?
    super_admin?
  end

  def new?
    create?
  end

  def update?
    manages_headquarter?(record.try(:id))
  end

  def edit?
    update?
  end

  def destroy?
    super_admin?
  end

  def show?
    true
  end

  # Only super admins work in any sede; everyone else works in their own.
  def switch?
    super_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
