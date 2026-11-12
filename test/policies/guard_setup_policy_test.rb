require "test_helper"

class GuardSetupPolicyTest < ActiveSupport::TestCase
  def policy(user, record = guard_setups(:one))
    GuardSetupPolicy.new(user, record)
  end

  test "only admins and super admins can list, see, create, edit and delete guard setups" do
    actions = %i[index? show? create? new? update? edit? destroy?]

    [ users(:admin_user), users(:super_admin) ].each do |admin|
      actions.each { |action| assert policy(admin).public_send(action), "#{admin.email} #{action}" }
    end
    [ users(:one), users(:two), users(:priest_one), nil ].each do |user|
      actions.each { |action| assert_not policy(user).public_send(action), "#{user&.email || 'visitor'} #{action}" }
    end
  end

  test "the scope has every guard setup" do
    assert_equal GuardSetup.count, GuardSetupPolicy::Scope.new(users(:admin_user), GuardSetup).resolve.count
  end
end
