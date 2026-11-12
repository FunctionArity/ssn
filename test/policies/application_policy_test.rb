require "test_helper"

class ApplicationPolicyTest < ActiveSupport::TestCase
  Record = Struct.new(:guardians)

  def policy(user, record = Record.new([]))
    ApplicationPolicy.new(user, record)
  end

  test "by default only super admins can do anything" do
    actions = %i[index? show? create? new? update? edit? destroy?]

    actions.each { |action| assert policy(users(:super_admin)).public_send(action), "super admin #{action}" }
    [ users(:admin_user), users(:one), nil ].each do |user|
      actions.each { |action| assert_not policy(user).public_send(action), "#{user&.email || 'visitor'} #{action}" }
    end
  end

  test "tells the user's type, and nobody's for visitors" do
    assert policy(users(:one)).regular?
    assert_not policy(users(:admin_user)).regular?
    assert policy(users(:admin_user)).is_admin?
    assert policy(users(:super_admin)).is_admin?
    assert_not policy(users(:one)).is_admin?

    visitor = policy(nil)
    assert_not visitor.super_admin?
    assert_not visitor.admin?
    assert_not visitor.regular?
  end

  test "is_vocal? tells whether the user is a vocal" do
    assert policy(users(:one)).is_vocal?
    assert_not policy(users(:priest_one)).is_vocal?
  end

  test "is_guardian? needs a guardian who is one of the record's guardians" do
    guardian = users(:two)

    assert policy(guardian, Record.new([ guardian ])).is_guardian?
    assert_not policy(guardian, Record.new([])).is_guardian?, "not one of the record's guardians"
    assert_not policy(users(:one), Record.new([ users(:one) ])).is_guardian?, "a vocal"
  end

  test "a policy scope must define how it resolves" do
    error = assert_raises(NoMethodError) { ApplicationPolicy::Scope.new(users(:one), Guard).resolve }

    assert_equal "You must define #resolve in ApplicationPolicy::Scope", error.message
  end
end
