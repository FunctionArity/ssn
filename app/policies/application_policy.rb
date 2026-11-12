# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    super_admin?
  end

  def show?
    super_admin?
  end

  def create?
    super_admin?
  end

  def new?
    create?
  end

  def update?
    super_admin?
  end

  def edit?
    update?
  end

  def destroy?
    super_admin?
  end

  def super_admin?
    user&.super_admin?
  end

  def admin?
    user&.admin?
  end

  def regular?
    user&.regular?
  end

  def is_admin?
    super_admin? || admin?
  end

  # Super admins manage every sede; admins only their own. The id is nil when the policy was given a class, not a
  # record, so then only super admins can.
  def manages_headquarter?(headquarter_id)
    super_admin? || (admin? && headquarter_id.present? && headquarter_id == user.headquarter_id)
  end

  def is_vocal?
    user.vocal?
  end

  def is_guardian?
    user.guardian? && record.guardians.include?(user)
  end
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end
end
