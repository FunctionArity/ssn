require "test_helper"

class GuardPolicyTest < ActiveSupport::TestCase
  test "history? is only allowed for super_admin" do
    guard = guards(:one)

    assert GuardPolicy.new(users(:super_admin), guard).history?
    assert_not GuardPolicy.new(users(:admin_user), guard).history?
    assert_not GuardPolicy.new(users(:one), guard).history?
  end
end
