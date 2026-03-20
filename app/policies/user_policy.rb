# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def create?
    is_admin?
  end

  def new?
    is_admin?
  end

  def update?
    is_admin?
  end

  def edit?
    is_admin?
  end

  def destroy?
    is_admin?
  end

  def lock?
    is_admin?
  end

  def unlock?
    is_admin?
  end

  def resend_invitation?
    is_admin?
  end

  def impersonate?
    super_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
