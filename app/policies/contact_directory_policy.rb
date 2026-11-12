# frozen_string_literal: true

class ContactDirectoryPolicy < ApplicationPolicy
  # Public directories are visible to anyone; members-only directories need a signed-in user.
  def show?
    record.visibility_public? || user.present?
  end

  def create?
    manages_headquarter?(record.try(:headquarter_id))
  end

  def new?
    create?
  end

  def update?
    create?
  end

  def edit?
    update?
  end

  def destroy?
    create?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      user.present? ? scope.all : scope.visibility_public
    end
  end
end
