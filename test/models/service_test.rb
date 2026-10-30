require "test_helper"

class ServiceTest < ActiveSupport::TestCase
  test "search_by_full_name ignores case, accents, word order and extra spaces" do
    assert_equal [ services(:one) ], Service.search_by_full_name("  PEREZ   juan ").to_a
  end

  test "search_by_full_name finds names containing a single word" do
    assert_equal [ services(:one) ], Service.search_by_full_name("perez").to_a
  end

  test "search_by_full_name requires every word" do
    assert_empty Service.search_by_full_name("juan lopez")
  end

  test "search without filters returns every service" do
    assert_equal Service.count, Service.search({}).count
  end

  test "search filters by full name ignoring case" do
    assert_equal [ services(:one) ], Service.search(full_name: "pérez").to_a
  end

  test "search treats like wildcards in the name literally" do
    assert_empty Service.search(full_name: "%")
  end

  test "search filters by health facility name" do
    services(:one).update_columns(health_facility_id: health_facilities(:one).id)

    assert_equal [ services(:one) ], Service.search(health_facility: "central").to_a
    assert_empty Service.search(health_facility: "santa rosa")
  end

  test "search filters by date" do
    assert_equal [ services(:completed_one) ], Service.search(date: "2026-03-02").to_a
    assert_empty Service.search(date: "not-a-date")
  end

  test "search filters by guard day" do
    assert_equal Service.count, Service.search(guard_day: guards(:one).day_number.to_s).count
    assert_empty Service.search(guard_day: "31")
  end

  test "search filters by caller phone ignoring its format" do
    services(:one).update_columns(caller_phone: "+54 261-555 1234")

    assert_equal [ services(:one) ], Service.search(caller_phone: "261 555").to_a
    assert_empty Service.search(caller_phone: "999")
    assert_empty Service.search(caller_phone: "abc")
  end

  test "search combines filters" do
    assert_equal [ services(:one) ], Service.search(full_name: "juan", date: "2026-03-01").to_a
    assert_empty Service.search(full_name: "juan", date: "2026-03-02")
  end

  test "can be completed when its guard is open" do
    service = services(:one)
    service.guard.update_column(:status, Guard.statuses[:open])

    assert service.can_be_completed?
  end

  test "cannot be completed when its guard is closed" do
    service = services(:one)
    service.guard.update_column(:status, Guard.statuses[:closed])

    assert_not service.can_be_completed?
  end

  test "cannot be moved to a closed guard" do
    service = services(:one)
    closed_guard = Guard.create!(day_number: 2, due_date: Date.current - 1, status: :closed,
                                 vocal: users(:one), priest: users(:two), guard_setup: guard_setups(:one), guardians: [ users(:one) ])

    assert_not service.update(guard: closed_guard)
    assert service.errors[:guard].any?
  end

  test "can be moved to an open guard" do
    service = services(:one)
    open_guard = Guard.create!(day_number: 2, due_date: Date.current, status: :open,
                               vocal: users(:one), priest: users(:two), guard_setup: guard_setups(:one), guardians: [ users(:one) ])

    assert service.update(guard: open_guard)
  end

  test "records a version with the changed attributes on update" do
    service = services(:one)

    assert_difference -> { service.versions.count }, 1 do
      service.update!(full_name: "Nombre Nuevo")
    end

    changes = service.versions.last.object_changes
    assert_equal [ services(:one).full_name_before_last_save, "Nombre Nuevo" ], changes["full_name"]
    assert_not changes.key?("updated_at")
  end

  test "does not record a version when only the position changes" do
    service = services(:one)

    assert_no_difference -> { service.versions.count } do
      service.update!(position: service.position + 1)
    end
  end

  test "clears comments that contain only empty rich text markup" do
    service = services(:one)

    [ "<p><br></p>", "<h2><br></h2>", "<p> &nbsp; </p>" ].each do |empty|
      service.update!(comments: empty)
      assert_nil service.comments, "expected #{empty.inspect} to be cleared"
    end

    service.update!(comments: "<p>Llamar antes</p>")
    assert_equal "<p>Llamar antes</p>", service.comments
  end
end
