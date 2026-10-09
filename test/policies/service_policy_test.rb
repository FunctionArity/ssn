require "test_helper"

class ServicePolicyTest < ActiveSupport::TestCase
  setup do
    @service = services(:one)
    @service.guard.update_column(:status, Guard.statuses[:open])
  end

  def policy(user, record = @service)
    ServicePolicy.new(user, record)
  end

  test "complete? is allowed for a member of the guard on a pending service of an open guard" do
    assert policy(users(:one)).complete?
  end

  test "complete? is denied when the guard is closed" do
    @service.guard.update_column(:status, Guard.statuses[:closed])
    assert_not policy(users(:one)).complete?
    assert_not policy(users(:super_admin)).complete?
  end

  test "complete? is denied for an already completed service" do
    assert_not policy(users(:one), services(:completed_one)).complete?
  end

  test "complete? is denied for a non-vocal user unrelated to the guard" do
    assert_not policy(users(:two)).complete?
  end

  test "history? is only allowed for super_admin" do
    assert policy(users(:super_admin)).history?
    assert_not policy(users(:admin_user)).history?
    assert_not policy(users(:one)).history?
  end

  test "change_guard? is allowed for vocals and super_admin only" do
    assert policy(users(:unrelated_vocal)).change_guard?
    assert policy(users(:super_admin)).change_guard?
    assert_not policy(users(:two)).change_guard?
  end
end
