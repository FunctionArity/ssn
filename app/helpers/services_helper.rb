module ServicesHelper
  # Tailwind classes for a service's colors: green once completed, red while pending, and a stronger red when it's
  # also urgent. Completed services don't need attention any more, so they're green even if they were urgent
  # (they keep the Urgente badge).
  SERVICE_COLORS = {
    completed: { card: "bg-green-50 border-gray-200", frame: "border-gray-200", header: "bg-gradient-to-r from-green-100 to-white", date: "text-green-600",
                 icon: "bg-green-200 text-green-700", dot: "bg-green-500", grip: "text-green-700", badge: "badge_green" },
    pending: { card: "bg-red-50 border-gray-200", frame: "border-gray-200", header: "bg-gradient-to-r from-red-100 to-white", date: "text-red-500",
               icon: "bg-red-200 text-red-700", dot: "bg-red-500", grip: "text-red-700", badge: "badge_red" },
    urgent: { card: "bg-red-100 border-red-400", frame: "border-red-400 ring-1 ring-red-400", header: "bg-gradient-to-r from-red-300 to-red-50", date: "text-red-800",
              icon: "bg-red-600 text-white", dot: "bg-red-600 animate-pulse", grip: "text-red-800", badge: "badge_red" }
  }.freeze

  def service_colors(service)
    SERVICE_COLORS[service_tone(service)]
  end

  # The "Urgente" badge, for urgent services: solid red while pending, solid green once completed, like their card.
  def service_urgent_badge(service)
    return unless service.urgent?

    tag.span(class: [ "badge_urgent", ("badge_urgent_completed" if service.completed?) ]) do
      safe_join([ tag.i(class: "ph-bold ph-siren"), t("services.priorities.urgent") ], " ")
    end
  end

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

  private

  # Completed wins over urgent: a done service needs no attention.
  def service_tone(service)
    case
    when service.completed? then :completed
    when service.urgent?    then :urgent
    else :pending
    end
  end

  def guard_option_label(guard)
    label = "#{l(guard.due_date, format: "%A").capitalize} #{l(guard.due_date, format: :long)}"
    label += " (#{t("guards.status.#{guard.status}")})" if guard.closed?
    label
  end
end
