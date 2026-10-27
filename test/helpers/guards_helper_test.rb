require "test_helper"

class GuardsHelperTest < ActionView::TestCase
  setup do
    @guard = guards(:one)
    @guard.due_date = Date.new(2026, 10, 27)
    @header = [
      "#{Guard.model_name.human} #{l(@guard.due_date, format: "%A").capitalize} #{l(@guard.due_date, format: :long)}",
      "#{Guard.human_attribute_name(:vocal)}: #{@guard.vocal.full_name}",
      "#{Guard.human_attribute_name(:priest)}: #{@guard.priest.full_name}"
    ].join("\n")
  end

  test "starts with the guard's day, vocal and priest, then each service's patient, caller and phone" do
    services = [
      Service.new(full_name: "Juan Pérez", caller_full_name: "Ana Pérez", caller_phone: "261 555 1234"),
      Service.new(full_name: "Maria López", caller_full_name: "Luis López", caller_phone: "261 555 9876")
    ]

    assert_equal <<~TEXT.chomp, guard_services_clipboard_text(@guard, services)
      #{@header}

      Juan Pérez
      #{Service.human_attribute_name(:caller_full_name)}: Ana Pérez
      #{Service.human_attribute_name(:caller_phone)}: 261 555 1234

      Maria López
      #{Service.human_attribute_name(:caller_full_name)}: Luis López
      #{Service.human_attribute_name(:caller_phone)}: 261 555 9876
    TEXT
  end

  test "header shows the weekday and date" do
    assert_match(/\AGuardia Martes 27 de octubre de 2026\n/, guard_services_clipboard_text(@guard, []))
  end

  test "skips blank caller fields" do
    services = [ Service.new(full_name: "Juan Pérez", caller_full_name: "", caller_phone: "261 555 1234") ]

    assert_equal "#{@header}\n\nJuan Pérez\n#{Service.human_attribute_name(:caller_phone)}: 261 555 1234",
                 guard_services_clipboard_text(@guard, services)
  end

  test "is only the header without services" do
    assert_equal @header, guard_services_clipboard_text(@guard, [])
  end
end
