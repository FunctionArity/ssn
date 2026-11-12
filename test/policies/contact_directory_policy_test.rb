require "test_helper"

class ContactDirectoryPolicyTest < ActiveSupport::TestCase
  def policy(user, record = contact_directories(:pastoral))
    ContactDirectoryPolicy.new(user, record)
  end

  test "members-only directories are shown to signed-in users only" do
    assert policy(users(:one)).show?
    assert_not policy(nil).show?
  end

  test "public directories are shown to everyone" do
    assert policy(nil, contact_directories(:public_directory)).show?
  end

  test "only admins and super admins can create, edit and delete" do
    [ users(:admin_user), users(:super_admin) ].each do |admin|
      assert policy(admin).create?, "#{admin.email} should create"
      assert policy(admin).update?, "#{admin.email} should update"
      assert policy(admin).destroy?, "#{admin.email} should destroy"
    end

    [ users(:one), users(:two) ].each do |user|
      assert_not policy(user).create?, "#{user.email} should not create"
      assert_not policy(user).update?, "#{user.email} should not update"
      assert_not policy(user).destroy?, "#{user.email} should not destroy"
    end
  end

  test "admins only manage their own sede's directories" do
    other = ContactDirectory.new(headquarter: headquarters(:two))

    assert_not policy(users(:admin_user), other).create?
    assert_not policy(users(:admin_user), other).update?
    assert_not policy(users(:admin_user), other).destroy?
    assert policy(users(:super_admin), other).update?
  end

  test "checked against the class, only super admins can create" do
    assert_not policy(users(:admin_user), ContactDirectory).create?
    assert policy(users(:super_admin), ContactDirectory).create?
  end

  test "scope returns every directory to signed-in users and only public ones to visitors" do
    assert_equal ContactDirectory.count, ContactDirectoryPolicy::Scope.new(users(:one), ContactDirectory).resolve.count
    assert_equal [ contact_directories(:public_directory) ], ContactDirectoryPolicy::Scope.new(nil, ContactDirectory).resolve.to_a
  end
end
