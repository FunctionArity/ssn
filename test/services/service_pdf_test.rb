require "test_helper"

class ServicePdfTest < ActiveSupport::TestCase
  setup do
    @service = services(:one)
  end

  test "renders a PDF binary string" do
    result = ServicePdf.new(@service).render

    assert_instance_of String, result
    assert result.start_with?("%PDF"), "output should start with PDF magic bytes"
  end

  test "rendered PDF is non-empty" do
    result = ServicePdf.new(@service).render

    assert result.bytesize > 0
  end

  test "renders without error when optional fields are blank" do
    service = Service.new(
      full_name: "Sin Datos",
      due_date: Date.today,
      guard: guards(:one)
    )

    assert_nothing_raised { ServicePdf.new(service).render }
  end

  test "renders without error when all optional fields are present" do
    service = services(:one)
    service.assign_attributes(
      age: "75",
      pathology: "Diabetes",
      health_status: "Grave",
      sacraments: "Unción",
      address: "Av. Corrientes 1234",
      health_facility_place: "Piso 3 Cama B",
      caller_full_name: "Ana García",
      caller_phone: "1122334455",
      caller_relationship: "Hija"
    )

    assert_nothing_raised { ServicePdf.new(service).render }
  end
end
