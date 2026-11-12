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

  test "each sede has its own health facilities" do
    quito_facility = in_quito { HealthFacility.create!(name: "Hospital Eugenio Espejo", address: "Av. Gran Colombia, Quito") }

    assert_not_includes HealthFacility.all, quito_facility
    in_quito { assert_equal [ quito_facility ], HealthFacility.all.to_a }
  end

  test "a service's health facility must be from its sede" do
    quito_facility = in_quito { HealthFacility.create!(name: "Hospital Eugenio Espejo", address: "Av. Gran Colombia, Quito") }
    service = services(:one)

    service.health_facility_id = quito_facility.id

    assert_not service.valid?
    assert service.errors.include?(:health_facility_id)
  end

  test "each sede has its own churches" do
    quito_church = in_quito { Church.create!(name: "Basílica del Voto Nacional") }

    assert_not_includes Church.all, quito_church
    in_quito { assert_equal [ quito_church ], Church.all.to_a }
  end

  test "a priest's church must be from their sede" do
    quito_church = in_quito { Church.create!(name: "Basílica del Voto Nacional") }
    priest = users(:priest_one)

    priest.church_id = quito_church.id

    assert_not priest.valid?
    assert priest.errors.include?(:church_id)
  end

  test "a sede with users can't be deleted" do
    assert_not headquarters(:one).destroy
    assert headquarters(:one).persisted?
  end

  test "a sede with users can't be deleted while working in another sede" do
    in_quito { create_user("vocal") }

    assert_not @quito.destroy
    assert @quito.reload.persisted?
  end

  test "authors from another sede are found" do
    service = in_quito do
      vocal = create_user("vocal")
      guard = quito_guard(due_date: Date.current, vocal: vocal)
      guard.save!
      guard.services.create!(full_name: "Servicio Quiteño", due_date: Date.current, created_by: users(:super_admin))
    end

    in_quito do
      assert_equal users(:super_admin), Service.find(service.id).created_by
      assert_equal users(:super_admin), Service.includes(:created_by).find(service.id).created_by
      assert_equal({ users(:super_admin).id.to_s => users(:super_admin) }, User.authors_of([ PaperTrail::Version.new(whodunnit: users(:super_admin).id.to_s) ]))
    end
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
