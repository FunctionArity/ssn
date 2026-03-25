require "test_helper"

class GuardPdfTest < ActiveSupport::TestCase
  setup do
    @guard = guards(:one)
  end

  test "renders a PDF binary string" do
    result = GuardPdf.new(@guard).render

    assert_instance_of String, result
    assert result.start_with?("%PDF"), "output should start with PDF magic bytes"
  end

  test "rendered PDF is non-empty" do
    result = GuardPdf.new(@guard).render

    assert result.bytesize > 0
  end

  test "renders without error when guard has no services" do
    guard = Guard.new(
      day_number: 1,
      due_date: Date.today,
      vocal: users(:one),
      priest: users(:two),
      guard_setup: guard_setups(:one)
    )
    guard.guardians << users(:one)

    assert_nothing_raised { GuardPdf.new(guard).render }
  end

  test "renders without error when guard has fewer than 3 services" do
    @guard.services.create!(full_name: "Extra Service", due_date: Date.today, created_by: users(:one))

    assert_nothing_raised { GuardPdf.new(@guard).render }
  end

  test "paginates when guard has more than 3 services" do
    4.times do |i|
      @guard.services.create!(full_name: "Service #{i}", due_date: Date.today, created_by: users(:one))
    end

    result = GuardPdf.new(@guard).render

    assert result.start_with?("%PDF")
  end

  test "renders without error when services have all optional fields blank" do
    @guard.services.create!(
      full_name: "Minimal Service",
      due_date: Date.today,
      created_by: users(:one)
    )

    assert_nothing_raised { GuardPdf.new(@guard).render }
  end

  test "renders without error when services have all optional fields present" do
    @guard.services.create!(
      full_name: "Full Service",
      due_date: Date.today,
      created_by: users(:one),
      age: 72,
      pathology: "Diabetes",
      health_status: "Grave",
      sacraments: "Unción",
      address: "Av. Corrientes 1234",
      health_facility_place: "Piso 3 Cama B",
      caller_full_name: "Ana García",
      caller_phone: "1122334455",
      caller_relationship: "Hija"
    )

    assert_nothing_raised { GuardPdf.new(@guard).render }
  end

  test "renders NRO label when service has nro assigned" do
    services(:one).update!(nro: 7)

    result = GuardPdf.new(@guard).render

    assert result.start_with?("%PDF")
    assert_nothing_raised { GuardPdf.new(@guard).render }
  end

  test "renders without error when some services have nro and some do not" do
    services(:one).update!(nro: 3)
    @guard.services.create!(full_name: "No Nro Service", due_date: Date.today, created_by: users(:one))

    assert_nothing_raised { GuardPdf.new(@guard).render }
  end
end
