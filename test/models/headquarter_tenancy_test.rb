require "test_helper"

# The fixtures are the Mendoza sede's (headquarters(:one)); Quito (headquarters(:two)) starts empty.
class HeadquarterTenancyTest < ActiveSupport::TestCase
  setup { @quito = headquarters(:two) }

  test "new records belong to the current sede" do
    user = in_quito { User.create!(email: "quito@example.test", first_name: "Ana", last_name: "Quito", password: "password123") }

    assert_equal @quito, user.headquarter
  end

  test "each sede only sees its own records" do
    quito_user = in_quito { create_user("vocal") }

    assert_not_includes User.all, quito_user
    in_quito { assert_equal [ quito_user ], User.all.to_a }
  end

  test "each sede can have its own open guard on the same day" do
    guard = in_quito { quito_guard(due_date: guards(:one).due_date) }

    in_quito { assert guard.save, guard.errors.full_messages.to_sentence }
  end

  test "a sede still has a single open guard per day" do
    guard = Guard.new(day_number: 1, due_date: guards(:one).due_date, vocal: users(:one), priest: users(:priest_one), guardian_ids: [ users(:two).id ])

    assert_not guard.valid?
    assert_includes guard.errors[:due_date], I18n.t("activerecord.errors.models.guard.attributes.due_date.open_guard_taken")
  end

  test "a guard's vocal must be from its sede" do
    guard = in_quito { quito_guard(due_date: Date.new(2026, 4, 1), vocal: users(:one)) }

    in_quito { assert_not guard.valid? }
  end

  test "each sede has its own priest schedule" do
    quito_priest = in_quito do
      create_user("priest").tap { |priest| PriestSetup.create!(priest: priest, week_number: 1, day_of_week: 1) }
    end
    first_monday = Date.new(2026, 3, 2)

    assert_equal users(:priest_one), User.current_priest(first_monday)
    in_quito { assert_equal quito_priest, User.current_priest(first_monday) }
  end

  test "a sede with users can't be deleted" do
    assert_not headquarters(:one).destroy
    assert headquarters(:one).persisted?
  end

  private

  def in_quito(&) = ActsAsTenant.with_tenant(@quito, &)

  def create_user(role)
    User.create!(email: "#{role}.#{SecureRandom.hex(4)}@example.test", first_name: role, last_name: "Quito", role: role, password: "password123")
  end

  def quito_guard(due_date:, vocal: create_user("vocal"))
    guardian_ids = [ create_user("guardian").id ]
    setup = GuardSetup.create!(day_number: due_date.day, vocal: create_user("vocal"), guardian_ids: guardian_ids)
    Guard.new(guard_setup: setup, day_number: due_date.day, due_date: due_date, vocal: vocal, priest: create_user("priest"), guardian_ids: guardian_ids)
  end
end
