# frozen_string_literal: true

class ContactDirectoryPolicy < ApplicationPolicy
  # Public directories are visible to anyone; members-only directories need a signed-in user.
  def show?
    record.visibility_public? || user.present?
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

  class Scope < ApplicationPolicy::Scope
    def resolve
      user.present? ? scope.all : scope.visibility_public
    end
  end
end
