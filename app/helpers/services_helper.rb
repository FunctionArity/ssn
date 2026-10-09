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

  # Comments are HTML from the Lexxy editor; older ones are plain text and keep their line breaks.
  def service_comments_html(comments)
    return if comments.blank?

    comments.match?(/<[a-z][^>]*>/i) ? sanitize(comments, scrubber: RichTextScrubber.new) : simple_format(comments, {}, wrapper_tag: "p")
  end

  private

  def guard_option_label(guard)
    label = "#{l(guard.due_date, format: "%A").capitalize} #{l(guard.due_date, format: :long)}"
    label += " (#{t("guards.status.#{guard.status}")})" if guard.closed?
    label
  end
end
