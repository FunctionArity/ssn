module ServicesHelper
  # Groups the guard choices so today's guard is easy to find: the service's current guard,
  # today's open guard, upcoming open guards, then older guards that were never closed.
  def guard_grouped_options(service, guards)
    current = guards.find { |g| g.id == service.guard_id_in_database }
    others  = (guards - [ current ]).select(&:open?)
    today   = Date.current

    groups = [
      [ t("services.form.guard_groups.current"), [ current ].compact ],
      [ t("services.form.guard_groups.today"), others.select { |g| g.due_date == today } ],
      [ t("services.form.guard_groups.upcoming"), others.select { |g| g.due_date > today }.sort_by(&:due_date) ],
      [ t("services.form.guard_groups.previous_open"), others.select { |g| g.due_date < today }.sort_by(&:due_date).reverse ]
    ].reject { |_, list| list.empty? }

    groups.map do |label, list|
      [ label, list.map { |g| [ guard_option_label(g), g.id ] } ]
    end
  end

  HISTORY_SKIPPED_ATTRIBUTES = %w[id created_at updated_at position].freeze

  # Attribute changes of a PaperTrail version, without bookkeeping columns.
  def service_version_changes(version)
    (version.object_changes || {}).except(*HISTORY_SKIPPED_ATTRIBUTES)
  end

  def service_history_attribute_name(attribute)
    Service.human_attribute_name(attribute.delete_suffix("_id"))
  end

  # Human-readable value for a stored attribute, resolving ids to the record they point to.
  def service_history_value(attribute, value)
    return tag.span("—", class: "text-gray-300") if value.nil? || value == ""

    case attribute
    when "guard_id"
      guard = Guard.find_by(id: value)
      guard ? "##{guard.day_number} – #{l(guard.due_date, format: :long)}" : "##{value}"
    when "health_facility_id"
      HealthFacility.find_by(id: value)&.name || "##{value}"
    when "created_by_id"
      User.find_by(id: value)&.full_name || "##{value}"
    when "status"
      status = value.is_a?(Integer) ? Service.statuses.key(value) : value
      t("services.status.#{status}", default: status.to_s)
    when "due_date"
      l(Date.parse(value.to_s), format: :long)
    else
      value.to_s
    end
  end

  private

  def guard_option_label(guard)
    label = "#{l(guard.due_date, format: "%A").capitalize} #{l(guard.due_date, format: :long)}"
    label += " (#{t("guards.status.#{guard.status}")})" if guard.closed?
    label
  end
end
