require "test_helper"

class PriestSetupPolicyTest < ActiveSupport::TestCase
  def policy(user, record = priest_setups(:one))
    PriestSetupPolicy.new(user, record)
  end

  test "everyone can see the priests' calendar" do
    [ users(:super_admin), users(:admin_user), users(:one), nil ].each do |user|
      assert policy(user, PriestSetup).index?, "#{user&.email || 'visitor'} index?"
    end
  end

  test "only admins and super admins can see, create, edit and delete priest setups" do
    actions = %i[show? create? new? update? edit? destroy?]

    [ users(:admin_user), users(:super_admin) ].each do |admin|
      actions.each { |action| assert policy(admin).public_send(action), "#{admin.email} #{action}" }
    end
    [ users(:one), users(:two), users(:priest_one), nil ].each do |user|
      actions.each { |action| assert_not policy(user).public_send(action), "#{user&.email || 'visitor'} #{action}" }
    end
  end

  test "the scope has every priest setup" do
    assert_equal PriestSetup.count, PriestSetupPolicy::Scope.new(users(:one), PriestSetup).resolve.count
  end
end
