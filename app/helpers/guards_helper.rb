module GuardsHelper
  # Plain text of the guard for the clipboard: a header with the day, vocal and priest,
  # then one block per service with patient, caller and phone.
  def guard_services_clipboard_text(guard, services)
    header = [
      "#{Guard.model_name.human} #{l(guard.due_date, format: "%A").capitalize} #{l(guard.due_date, format: :long)}",
      "#{Guard.human_attribute_name(:vocal)}: #{guard.vocal.full_name}",
      "#{Guard.human_attribute_name(:priest)}: #{guard.priest.full_name}"
    ].join("\n")

    blocks = services.map do |service|
      [
        service.full_name,
        *%i[caller_full_name caller_phone].filter_map do |attribute|
          value = service.public_send(attribute)
          "#{Service.human_attribute_name(attribute)}: #{value}" if value.present?
        end
      ].join("\n")
    end

    [ header, *blocks ].join("\n\n")
  end
end
