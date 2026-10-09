require "test_helper"

class HistoryHelperTest < ActionView::TestCase
  include HistoryHelper

  def version(event, object_changes = {})
    PaperTrail::Version.new(event: event, object_changes: object_changes)
  end

  test "history_changes leaves out bookkeeping columns" do
    changes = history_changes(version("update", {
      "id" => [ nil, 1 ], "created_at" => [ nil, "x" ], "updated_at" => [ "a", "b" ],
      "position" => [ 1, 2 ], "full_name" => [ "A", "B" ]
    }))

    assert_equal({ "full_name" => [ "A", "B" ] }, changes)
  end

  test "history_changes handles versions without recorded changes" do
    assert_equal({}, history_changes(version("update", nil)))
  end

  test "history_attribute_name names foreign keys after their association" do
    assert_equal Service.human_attribute_name(:guard), history_attribute_name(Service, "guard_id")
    assert_equal Service.human_attribute_name(:full_name), history_attribute_name(Service, "full_name")
  end

  test "history_value shows a dash for blank values" do
    assert_includes history_value(Service, "full_name", nil), "—"
    assert_includes history_value(Service, "full_name", ""), "—"
  end

  test "history_value translates statuses stored as keys or integers" do
    assert_equal I18n.t("services.status.completed"), history_value(Service, "status", "completed")
    assert_equal I18n.t("services.status.pending"), history_value(Service, "status", 0)
    assert_equal I18n.t("guards.status.closed"), history_value(Guard, "status", "closed")
    assert_equal I18n.t("guards.status.open"), history_value(Guard, "status", 0)
  end

  test "history_value resolves foreign keys to a readable label" do
    guard = guards(:one)

    assert_equal "##{guard.day_number} – #{I18n.l(guard.due_date, format: :long)}", history_value(Service, "guard_id", guard.id)
    assert_equal users(:one).full_name, history_value(Service, "created_by_id", users(:one).id)
    assert_equal health_facilities(:one).name, history_value(Service, "health_facility_id", health_facilities(:one).id)
    assert_equal users(:two).full_name, history_value(Guard, "priest_id", users(:two).id)
  end

  test "history_value falls back to the id when the referenced record no longer exists" do
    assert_equal "#999999", history_value(Service, "health_facility_id", 999_999)
  end

  test "history_value formats date attributes" do
    assert_equal I18n.l(Date.new(2026, 10, 9), format: :long), history_value(Service, "due_date", "2026-10-09")
  end

  test "history_value shows other values as text" do
    assert_equal "89", history_value(Service, "age", 89)
  end

  test "history_status_badge_class colors each status" do
    assert_equal "badge_green", history_status_badge_class(Service, "completed")
    assert_equal "badge_red", history_status_badge_class(Service, "pending")
    assert_equal "badge_green", history_status_badge_class(Guard, "open")
    assert_equal "badge_red", history_status_badge_class(Guard, 1)
  end

  test "history_event_icon uses the event icon when the status did not change" do
    assert_equal "ph-plus", history_event_icon(Service, version("create"), {}).first
    assert_equal "ph-pencil-simple", history_event_icon(Service, version("update"), { "full_name" => [ "A", "B" ] }).first
    assert_equal "ph-trash", history_event_icon(Service, version("destroy"), {}).first
  end

  test "history_event_icon uses the new status icon for status changes" do
    assert_equal "ph-check", history_event_icon(Service, version("update"), { "status" => %w[pending completed] }).first
    assert_equal "ph-arrow-counter-clockwise", history_event_icon(Service, version("update"), { "status" => %w[completed pending] }).first
    assert_equal "ph-lock-simple", history_event_icon(Guard, version("update"), { "status" => %w[open closed] }).first
    assert_equal "ph-lock-simple-open", history_event_icon(Guard, version("update"), { "status" => %w[closed open] }).first
  end

  test "history_value translates other enums such as role and user type" do
    assert_equal I18n.t("activerecord.attributes.user.roles.priest"), history_value(User, "role", "priest")
    assert_equal I18n.t("activerecord.attributes.user.user_types.super_admin"), history_value(User, "user_type", 2)
  end

  test "history_value formats datetime attributes" do
    time = Time.zone.local(2026, 10, 9, 18, 30)
    assert_equal I18n.l(time, format: :long), history_value(User, "locked_at", time.iso8601)
  end

  test "history_value shows polymorphic references by id" do
    assert_equal "#5", history_value(User, "invited_by_id", 5)
  end

  test "history_value shows rich text as plain text" do
    assert_equal "Paciente en sala 3 Llamar antes",
                 history_value(Service, "comments", "<p>Paciente en <strong>sala 3</strong></p><p>Llamar antes</p>")
  end
end
