module HistoryHelper
  HISTORY_SKIPPED_ATTRIBUTES = %w[id created_at updated_at position].freeze

  # Badge and timeline icon for each status value of the tracked models.
  HISTORY_STATUS_STYLES = {
    "pending"   => [ "badge_red", "ph-arrow-counter-clockwise", "bg-amber-100 text-amber-700 ring-amber-50" ],
    "completed" => [ "badge_green", "ph-check", "bg-green-100 text-green-700 ring-green-50" ],
    "open"      => [ "badge_green", "ph-lock-simple-open", "bg-green-100 text-green-700 ring-green-50" ],
    "closed"    => [ "badge_red", "ph-lock-simple", "bg-gray-200 text-gray-700 ring-gray-100" ]
  }.freeze

  HISTORY_EVENT_STYLES = {
    "create"  => [ "ph-plus", "bg-green-100 text-green-700 ring-green-50" ],
    "update"  => [ "ph-pencil-simple", "bg-blue-100 text-blue-700 ring-blue-50" ],
    "destroy" => [ "ph-trash", "bg-red-100 text-red-700 ring-red-50" ]
  }.freeze

  # Attribute changes of a PaperTrail version, without bookkeeping columns.
  def history_changes(version)
    (version.object_changes || {}).except(*HISTORY_SKIPPED_ATTRIBUTES)
  end

  def history_attribute_name(model, attribute)
    model.human_attribute_name(attribute.delete_suffix("_id"))
  end

  # Human-readable value for a stored attribute, resolving foreign keys to the record they point to.
  def history_value(model, attribute, value)
    return tag.span("—", class: "text-gray-300") if value.nil? || value == ""

    if attribute == "status"
      status = history_status_value(model, value)
      return t("#{model.model_name.plural}.status.#{status}", default: status.to_s)
    end

    if (enum = model.defined_enums[attribute])
      key = value.is_a?(Integer) ? enum.key(value) : value.to_s
      return t("activerecord.attributes.#{model.model_name.i18n_key}.#{attribute.pluralize}.#{key}", default: key.to_s.humanize)
    end

    if (association = model.reflect_on_all_associations(:belongs_to).find { |a| a.foreign_key.to_s == attribute })
      return "##{value}" if association.polymorphic?
      return history_record_label(association.klass.find_by(id: value)) || "##{value}"
    end

    case model.type_for_attribute(attribute).type
    when :date then l(Date.parse(value.to_s), format: :long)
    when :datetime then l(Time.zone.parse(value.to_s), format: :long)
    else value.to_s
    end
  end

  # Status as its enum key, whether the version stored the key or the integer.
  def history_status_value(model, value)
    value.is_a?(Integer) ? model.statuses.key(value) : value.to_s
  end

  def history_status_badge_class(model, value)
    HISTORY_STATUS_STYLES.dig(history_status_value(model, value), 0) || "badge_blue"
  end

  # Timeline icon: a status change gets the icon of the new status, anything else the icon of its event.
  def history_event_icon(model, version, changes)
    if version.event == "update" && changes.key?("status")
      _badge, icon, icon_class = HISTORY_STATUS_STYLES[history_status_value(model, changes["status"].last)]
      return [ icon, icon_class ] if icon
    end

    HISTORY_EVENT_STYLES.fetch(version.event, HISTORY_EVENT_STYLES["update"])
  end

  private

  def history_record_label(record)
    case record
    when nil then nil
    when Guard then "##{record.day_number} – #{l(record.due_date, format: :long)}"
    else record.try(:full_name) || record.try(:name) || "##{record.id}"
    end
  end
end
