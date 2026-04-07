require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Validations
  test "is valid with all required fields" do
    user = User.new(first_name: "Ana", last_name: "García", email: "ana@garcia.com", phone: "1234567890", password: "password123")
    assert user.valid?
  end

  test "is invalid without first_name" do
    user = users(:one)
    user.first_name = nil
    assert_not user.valid?
    assert user.errors[:first_name].any?
  end

  test "is invalid without last_name" do
    user = users(:one)
    user.last_name = nil
    assert_not user.valid?
    assert user.errors[:last_name].any?
  end

  test "is invalid without email" do
    user = users(:one)
    user.email = nil
    assert_not user.valid?
    assert user.errors[:email].any?
  end

  test "is invalid with duplicate email" do
    user = User.new(first_name: "Ana", last_name: "García", email: users(:one).email, phone: "1234567890", password: "password123")
    assert_not user.valid?
    assert user.errors[:email].any?
  end

  # Roles
  test "defaults to guardian role" do
    user = User.new
    assert user.guardian?
  end

  test "can be assigned vocal role" do
    user = users(:one)
    user.vocal!
    assert user.vocal?
  end

  test "can be assigned priest role" do
    user = users(:one)
    user.priest!
    assert user.priest?
  end

  # Church association
  test "priest can belong to a church" do
    priest = users(:priest_one)
    church = churches(:one)
    priest.update!(church: church)
    assert_equal church, priest.reload.church
  end

  test "church is optional for priest" do
    priest = users(:priest_one)
    priest.church = nil
    assert priest.valid?
  end

  test "church_id is cleared when role is not priest" do
    priest = users(:priest_one)
    priest.update!(church: churches(:one))

    # Simulate controller behavior: church_id is cleared when role != priest
    priest.update!(role: :guardian, church: nil)
    assert_nil priest.reload.church_id
  end

  # Scopes
  test "guardians scope returns only guardians" do
    assert User.guardians.all?(&:guardian?)
  end

  test "vocals scope returns only vocals" do
    assert User.vocals.all?(&:vocal?)
  end

  test "priests scope returns only priests" do
    assert User.priests.all?(&:priest?)
  end

  test "priests_without_setup excludes priests with a setup" do
    priest = users(:priest_one)
    assert_not User.priests_without_setup.include?(priest)
  end

  # Instance methods
  test "full_name joins first and last name" do
    user = users(:one)
    assert_equal "#{user.last_name} #{user.first_name}", user.full_name
  end

  test "role_badge_class returns badge_green for guardian" do
    assert_equal "badge_green", users(:two).role_badge_class
  end

  test "role_badge_class returns badge_red for vocal" do
    users(:one).vocal!
    assert_equal "badge_red", users(:one).role_badge_class
  end

  test "role_badge_class returns badge_purple for priest" do
    assert_equal "badge_purple", users(:priest_one).role_badge_class
  end

  # Class methods
  test "week_of_month returns 1 for the first week" do
    date = Date.new(2026, 3, 1) # Sunday, first day of March 2026
    assert_equal 1, User.week_of_month(date)
  end

  test "week_of_month returns 2 for the second week" do
    date = Date.new(2026, 3, 9) # Monday, second Monday of March 2026
    assert_equal 2, User.week_of_month(date)
  end
end
