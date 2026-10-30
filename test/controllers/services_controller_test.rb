require "test_helper"

class ServicesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActionCable::TestHelper
  include ActiveJob::TestHelper

  # users(:one)           — vocal role, vocal of guards(:one), guardian of guards(:one)
  # users(:vocal_guardian) — vocal role, guardian of guards(:one) but NOT its vocal
  # users(:unrelated_vocal) — vocal role, no relationship to guards(:one)
  # users(:two)           — guardian role, no relationship to guards(:one) (is priest)
  # users(:super_admin)   — super_admin user_type, can do everything

  setup do
    @user = users(:one)
    @service = services(:one)
    sign_in @user
  end

  test "should get index" do
    get services_url
    assert_response :success
  end

  test "duplicates lists services with the same name from the last 2 months" do
    travel_to Date.new(2026, 4, 15) do
      get duplicates_services_url, params: { full_name: "juan  perez " }

      assert_response :success
      assert_select "turbo-frame#service_duplicates a[href=?]", service_path(services(:one)), count: 1
      assert_select "a[href=?]", service_path(services(:completed_one)), count: 0
    end
  end

  test "duplicates lists services whose name contains the typed word" do
    travel_to Date.new(2026, 4, 15) do
      get duplicates_services_url, params: { full_name: "perez" }

      assert_select "a[href=?]", service_path(services(:one)), count: 1
    end
  end

  test "duplicates lists nothing for a blank name" do
    travel_to Date.new(2026, 4, 15) do
      get duplicates_services_url, params: { full_name: "  " }

      assert_response :success
      assert_select "a[href=?]", service_path(services(:one)), count: 0
    end
  end

  test "duplicates opens the address on Google Maps in a new tab and hides the pathology" do
    services(:one).update_columns(address: "Portugal 1572", pathology: "enfermedad grave")

    travel_to Date.new(2026, 4, 15) do
      get duplicates_services_url, params: { full_name: "Juan Pérez" }

      assert_select "a[href=?][target=_blank]", "https://maps.google.com/?q=Portugal%201572", text: "Portugal 1572", count: 1
      assert_no_match "enfermedad grave", response.body
    end
  end

  test "duplicates opens the health facility on Google Maps in a new tab" do
    services(:one).update_columns(health_facility_id: health_facilities(:one).id)

    travel_to Date.new(2026, 4, 15) do
      get duplicates_services_url, params: { full_name: "Juan Pérez" }

      assert_select "a[href^='https://maps.google.com/'][target=_blank]", text: health_facilities(:one).name, count: 1
    end
  end

  test "duplicates links open in a new tab and offer no actions" do
    services(:one).guard.update_column(:status, Guard.statuses[:open])

    travel_to Date.new(2026, 4, 15) do
      get duplicates_services_url, params: { full_name: "Juan Pérez" }

      assert_select "a[href=?][target=_blank]", service_path(services(:one))
      assert_select "a[href=?]:not([target=_blank])", service_path(services(:one)), count: 0
      assert_select "a[href=?][target=_blank]", guard_path(services(:one).guard)
      assert_select "form[action=?]", complete_service_path(services(:one)), count: 0
    end
  end

  test "duplicates leaves out services older than 2 months" do
    travel_to Date.new(2026, 5, 2) do
      get duplicates_services_url, params: { full_name: "Juan Pérez" }

      assert_response :success
      assert_select "turbo-frame#service_duplicates"
      assert_select "a[href=?]", service_path(services(:one)), count: 0
    end
  end

  test "new wires the duplicate lookup and keeps the modal outside the form" do
    get new_service_url

    assert_select "[data-controller=service-duplicates][data-service-duplicates-url-value=?]", duplicates_services_path
    assert_select "input[name='service[full_name]'][data-service-duplicates-target=input]", count: 1
    assert_select "button.hidden[data-service-duplicates-target=button]", text: I18n.t("services.form.duplicates_link"), count: 1
    assert_select "span.hidden[data-service-duplicates-target=spinner] i.ph-spinner", count: 1
    assert_select "[data-service-duplicates-target=modal] turbo-frame#service_duplicates", count: 1
    assert_select "form [data-service-duplicates-target=modal]", count: 0
  end

  test "edit does not look up duplicates" do
    get edit_service_url(@service)

    assert_response :success
    assert_select "[data-controller=service-duplicates]", count: 0
    assert_select "[data-service-duplicates-target]", count: 0
  end

  test "index shows no search results until a filter is used" do
    get services_url

    assert_response :success
    assert_select "turbo-frame#services_results"
    assert_select "[data-services-search-target=spinner]", count: 1
    assert_select "[data-services-search-target=results] *", count: 0
  end

  test "index hides the filters and prompt by default behind an icon button next to new service" do
    show_label = I18n.t("services.index.show_filters")

    get services_url

    assert_select "[data-controller=services-search]" do
      assert_select "button[data-action='services-search#toggleFilters'][aria-expanded=false][title=?][aria-label=?] + a[href=?]", show_label, show_label, new_service_path, count: 1
      assert_select "button[data-action='services-search#toggleFilters']", text: "", count: 1
      assert_select "[data-services-search-target=filters][hidden]" do
        assert_select "form[data-services-search-target=form]", count: 1
        assert_select "p[data-services-search-target=prompt]:not(.hidden)", text: I18n.t("services.search_form.prompt"), count: 1
      end
    end
  end

  test "index keeps the filters open while filters are active" do
    hide_label = I18n.t("services.index.hide_filters")

    get services_url, params: { full_name: "juan" }

    assert_select "button[data-action='services-search#toggleFilters'][aria-expanded=true][title=?]", hide_label, count: 1
    assert_select "[data-services-search-target=filters]:not([hidden]) form", count: 1
    assert_select "p.hidden[data-services-search-target=prompt]", count: 1
  end

  test "index lists services matching the filters" do
    get services_url, params: { full_name: "juan" }

    assert_response :success
    assert_select "turbo-frame#service_#{services(:one).id}", count: 1
    assert_select "turbo-frame#service_#{services(:completed_one).id}", count: 0
  end

  test "index shows a message when nothing matches" do
    get services_url, params: { full_name: "nobody" }

    assert_response :success
    assert_match I18n.t("services.search_results.no_results"), response.body
  end

  test "index paginates search results and keeps the filters in the links" do
    guard = guards(:one)
    13.times { |index| Service.create!(full_name: "Paginado #{index}", due_date: Date.new(2026, 3, 1), guard: guard, created_by: @user) }

    get services_url, params: { full_name: "paginado" }
    assert_select "#services_results [data-services-search-target=results] turbo-frame", count: 12
    assert_select "a[href=?][data-turbo-frame=services_results]", services_path(full_name: "paginado", page: 2)

    get services_url, params: { full_name: "paginado", page: 2 }
    assert_select "#services_results [data-services-search-target=results] turbo-frame", count: 1
    assert_select "a[href=?]", services_path(full_name: "paginado", page: 1)
  end

  test "index falls back to the last page when the page is out of range" do
    get services_url, params: { full_name: "juan", page: 99 }

    assert_response :success
    assert_select "turbo-frame#service_#{services(:one).id}", count: 1
  end

  test "index lists matches from the current guard with the results and hides the guard while searching" do
    guards(:one).update_columns(due_date: Date.current, status: Guard.statuses[:open])
    other_guard = Guard.create!(day_number: 2, due_date: Date.current - 3, vocal: @user, priest: users(:two),
                                guard_setup: guard_setups(:one), guardians: [ @user ])
    other_service = Service.create!(full_name: "Juan Gómez", due_date: Date.current - 3, guard: other_guard, created_by: @user)

    get services_url, params: { full_name: "juan" }

    assert_response :success
    assert_select "[data-services-search-target=results] turbo-frame#service_#{other_service.id}", count: 1
    assert_select "[data-services-search-target=results] turbo-frame#service_#{services(:one).id}", count: 1
    assert_select "turbo-frame#service_#{services(:one).id}[draggable]", count: 0
    assert_select "turbo-frame#service_#{services(:one).id}", count: 1
    assert_select "#services", count: 0
    assert_select "[data-services-search-target=guard]", count: 0
    assert_no_match I18n.t("services.index.current_guard"), response.body
  end

  test "index keeps the current guard sortable and pending services visible without filters" do
    guards(:one).update_columns(due_date: Date.current, status: Guard.statuses[:open])
    other_guard = Guard.create!(day_number: 2, due_date: Date.current - 3, vocal: @user, priest: users(:two),
                                guard_setup: guard_setups(:one), guardians: [ @user ])
    pending_service = Service.create!(full_name: "Ana Díaz", due_date: Date.current - 3, guard: other_guard, created_by: @user)

    get services_url

    assert_select "[data-services-search-target=guard]:not([hidden]) #services[data-controller=service-reorder] turbo-frame#service_#{services(:one).id}[draggable]", count: 1
    assert_select "turbo-frame#service_#{services(:completed_one).id}", count: 1
    assert_select "turbo-frame#service_#{pending_service.id}", count: 1

    get services_url, params: { full_name: "juan" }

    assert_select "turbo-frame#service_#{pending_service.id}", count: 0
  end

  test "new without guard_id is allowed for vocal user" do
    get new_service_url
    assert_response :success
  end

  test "new assigns the only open guard opened in the last 12 hours" do
    travel_to Time.zone.local(2026, 10, 27, 2, 0) do
      guards(:one).update_columns(due_date: Date.new(2026, 10, 26))

      get new_service_url
    end

    assert_response :success
    assert_select "input[type=hidden][name='service[guard_id]'][value='#{guards(:one).id}']"
    assert_select "select[name='service[guard_id]']", count: 0
  end

  test "new shows a guard drop-down when several open guards qualify" do
    travel_to Time.zone.local(2026, 10, 27, 2, 0) do
      guards(:one).update_columns(due_date: Date.new(2026, 10, 26))
      upcoming = Guard.create!(day_number: 28, due_date: Date.new(2026, 10, 28), vocal: @user, priest: users(:two),
                               guard_setup: guard_setups(:one), guardians: [ @user ])

      get new_service_url

      assert_response :success
      assert_select "select[name='service[guard_id]'][required]" do
        assert_select "option[value='']", count: 1
        assert_select "option[value='#{guards(:one).id}']", count: 1
        assert_select "option[value='#{upcoming.id}']", count: 1
      end
    end
  end

  test "new warns when no open guard qualifies" do
    travel_to Time.zone.local(2026, 10, 27, 2, 0) do
      guards(:one).update_columns(due_date: Date.new(2026, 10, 25))

      get new_service_url
    end

    assert_response :success
    assert_select "select[name='service[guard_id]']", count: 0
    assert_match I18n.t("services.form.no_guard_warning"), response.body
  end

  test "should get new with guard_id param" do
    get new_service_url, params: { guard_id: guards(:one).id }
    assert_response :success
  end

  test "should get show" do
    get service_url(@service)
    assert_response :success
  end

  test "show includes health facility name in clipboard text" do
    @service.update!(health_facility: health_facilities(:one))
    get service_url(@service)
    assert_response :success
    assert_select "button[data-clipboard-text-value*=?]", health_facilities(:one).name
  end

  test "should get edit" do
    get edit_service_url(@service)
    assert_response :success
  end

  test "edit guard dropdown lists only open guards and the service's current guard" do
    sign_in users(:super_admin)
    @service.guard.update_column(:status, Guard.statuses[:closed])
    other_open = Guard.create!(day_number: 2, due_date: Date.current, status: :open,
                               vocal: users(:one), priest: users(:two), guard_setup: guard_setups(:one), guardians: [ users(:one) ])
    other_closed = Guard.create!(day_number: 3, due_date: Date.current - 2, status: :closed,
                                 vocal: users(:one), priest: users(:two), guard_setup: guard_setups(:one), guardians: [ users(:one) ])

    get edit_service_url(@service)

    assert_response :success
    assert_select "select[name='service[guard_id]']" do
      assert_select "option[value='#{other_open.id}']"
      assert_select "option[value='#{@service.guard_id}'][selected]"
      assert_select "option[value='#{other_closed.id}']", count: 0
    end
  end

  test "edit shows guard dropdown for a vocal" do
    sign_in users(:unrelated_vocal)
    get edit_service_url(@service)
    assert_select "select[name='service[guard_id]']"
  end

  test "edit hides guard dropdown for a non-vocal guardian" do
    guardian = users(:two).tap { |u| u.update_columns(role: User.roles[:guardian]) }
    @service.guard.guardians << guardian
    sign_in guardian
    get edit_service_url(@service)
    assert_response :success
    assert_select "select[name='service[guard_id]']", count: 0
  end

  test "update changes guard for a vocal" do
    other_open = Guard.create!(day_number: 2, due_date: Date.current, status: :open,
                               vocal: users(:one), priest: users(:two), guard_setup: guard_setups(:one), guardians: [ users(:one) ])
    patch service_url(@service), params: { service: { guard_id: other_open.id } }
    assert_redirected_to service_url(@service)
    assert_equal other_open, @service.reload.guard
  end

  test "update ignores guard change for a non-vocal guardian" do
    guardian = users(:two).tap { |u| u.update_columns(role: User.roles[:guardian]) }
    @service.guard.guardians << guardian
    other_open = Guard.create!(day_number: 2, due_date: Date.current, status: :open,
                               vocal: users(:one), priest: users(:two), guard_setup: guard_setups(:one), guardians: [ users(:one) ])
    sign_in guardian
    patch service_url(@service), params: { service: { full_name: "Updated", guard_id: other_open.id } }
    assert_redirected_to service_url(@service)
    assert_equal guards(:one), @service.reload.guard
    assert_equal "Updated", @service.full_name
  end

  test "should create service" do
    assert_difference("Service.count") do
      post services_url, params: {
        service: {
          full_name: "Carlos García",
          due_date: Date.current,
          guard_id: guards(:one).id
        }
      }
    end

    assert_redirected_to service_url(Service.last)
  end

  test "should not create service with invalid params" do
    assert_no_difference("Service.count") do
      post services_url, params: {
        service: { full_name: "", due_date: "", guard_id: guards(:one).id }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should update service" do
    patch service_url(@service), params: {
      service: { full_name: "Nombre Actualizado" }
    }

    assert_redirected_to service_url(@service)
    assert_equal "Nombre Actualizado", @service.reload.full_name
  end

  test "should not update service with invalid params" do
    patch service_url(@service), params: {
      service: { full_name: "" }
    }

    assert_response :unprocessable_entity
  end

  test "should destroy service" do
    assert_difference("Service.count", -1) do
      delete service_url(@service)
    end

    assert_redirected_to services_url
  end

  test "should complete service" do
    post complete_service_url(@service)

    assert_redirected_to service_url(@service)
    assert @service.reload.completed?
  end

  test "should complete service via turbo_stream" do
    post complete_service_url(@service), headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert @service.reload.completed?
  end

  test "should not complete service when its guard is closed" do
    @service.guard.update_column(:status, Guard.statuses[:closed])
    post complete_service_url(@service)

    assert_redirected_to root_path
    assert @service.reload.pending?
  end

  test "should not complete service for a non-vocal user unrelated to the guard" do
    sign_in users(:two)
    post complete_service_url(@service)

    assert_redirected_to root_path
    assert @service.reload.pending?
  end

  test "show displays edit, complete and destroy actions when permitted" do
    get service_url(@service)

    assert_select "a[href='#{edit_service_path(@service)}']"
    assert_select "form[action='#{complete_service_path(@service)}']"
    assert_select "form[action='#{service_path(@service)}'] input[name='_method'][value='delete']"
  end

  test "show hides edit, complete and destroy actions when not permitted" do
    sign_in users(:two)
    get service_url(@service)

    assert_response :success
    assert_select "a[href='#{edit_service_path(@service)}']", count: 0
    assert_select "form[action='#{complete_service_path(@service)}']", count: 0
    assert_select "form[action='#{service_path(@service)}'] input[name='_method'][value='delete']", count: 0
  end

  test "show hides complete action when the guard is closed" do
    @service.guard.update_column(:status, Guard.statuses[:closed])
    get service_url(@service)

    assert_select "a[href='#{edit_service_path(@service)}']"
    assert_select "form[action='#{complete_service_path(@service)}']", count: 0
  end

  test "show warns to reassign a pending service whose guard is closed" do
    @service.guard.update_column(:status, Guard.statuses[:closed])
    get service_url(@service)

    assert_select "span", text: I18n.t("services.show.reassign_to_open_guard")
  end

  test "show does not warn when the guard is open or the service is completed" do
    get service_url(@service)
    assert_select "span", text: I18n.t("services.show.reassign_to_open_guard"), count: 0

    completed = services(:completed_one)
    completed.guard.update_column(:status, Guard.statuses[:closed])
    get service_url(completed)
    assert_select "span", text: I18n.t("services.show.reassign_to_open_guard"), count: 0
  end

  test "should move service to a new position within its guard" do
    other = services(:completed_one)
    assert_equal 1, @service.position
    assert_equal 2, other.position

    patch move_service_url(@service), params: { position: 2 }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal 2, @service.reload.position
    assert_equal 1, other.reload.position
  end

  test "should move service for a guardian unrelated to the guard" do
    sign_out @user
    sign_in users(:two)

    patch move_service_url(@service), params: { position: 2 }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal 2, @service.reload.position
  end

  test "should not allow a priest to move a service" do
    sign_out @user
    sign_in users(:priest_one)

    patch move_service_url(@service), params: { position: 2 }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_redirected_to root_path
    assert_equal 1, @service.reload.position
  end

  test "should broadcast the guard services list when a service is completed" do
    assert_broadcasts("guard_#{@service.guard_id}", 1) do
      perform_enqueued_jobs do
        post complete_service_url(@service), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end
    end
  end

  test "should broadcast the guard services list when a service is updated" do
    assert_broadcasts("guard_#{@service.guard_id}", 1) do
      perform_enqueued_jobs do
        patch service_url(@service), params: { service: { full_name: "Nombre Actualizado" } }
      end
    end
  end

  test "should broadcast the reordered guard services list to other devices" do
    # Only the new guard-scoped broadcast targets this stream, so a single message proves it fired.
    assert_broadcasts("guard_#{@service.guard_id}", 1) do
      perform_enqueued_jobs do
        patch move_service_url(@service), params: { position: 2 }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end
    end
  end

  test "should additionally broadcast the services grid when the guard is today's open guard" do
    guard = guards(:one)
    guard.update!(due_date: Date.current, status: :open)

    # 3 jobs: the service's own after_update_commit broadcast, the guard-scoped list, and the services grid.
    assert_enqueued_jobs 3, only: Turbo::Streams::ActionBroadcastJob do
      patch move_service_url(@service), params: { position: 2 }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
  end

  test "should not broadcast the services grid when the guard is not today's open guard" do
    # 2 jobs: the service's own after_update_commit broadcast and the guard-scoped list (no services grid).
    assert_enqueued_jobs 2, only: Turbo::Streams::ActionBroadcastJob do
      patch move_service_url(@service), params: { position: 2 }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
  end

  test "should move service and replace the services index grid when context is services_index" do
    other = services(:completed_one)

    patch move_service_url(@service), params: { position: 2, context: "services_index" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal 2, @service.reload.position
    assert_equal 1, other.reload.position
    assert_includes response.body, 'target="services"'
  end

  test "should get pdf" do
    get pdf_service_url(@service)

    assert_response :success
    assert_equal "application/pdf", response.media_type
  end

  test "should set created_by to current user on create" do
    post services_url, params: {
      service: { full_name: "Test User", due_date: Date.current, guard_id: guards(:one).id }
    }

    assert_equal @user, Service.last.created_by
  end

  test "should require authentication" do
    sign_out @user
    get services_url
    assert_redirected_to new_user_session_path
  end

  # ---------------------------------------------------------------------------
  # Policy tests for new
  # ---------------------------------------------------------------------------

  test "new allowed for guardian of the guard" do
    sign_in users(:vocal_guardian)
    get new_service_url, params: { guard_id: guards(:one).id }
    assert_response :success
  end

  test "new allowed for super_admin" do
    sign_in users(:super_admin)
    get new_service_url, params: { guard_id: guards(:one).id }
    assert_response :success
  end

  test "new allowed for any vocal user" do
    sign_in users(:unrelated_vocal)
    get new_service_url, params: { guard_id: guards(:one).id }
    assert_response :success
  end

  test "new forbidden for non-vocal user unrelated to the guard" do
    sign_in users(:two)
    get new_service_url, params: { guard_id: guards(:one).id }
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Policy tests for create
  # ---------------------------------------------------------------------------

  test "create allowed for guardian of the guard" do
    sign_in users(:vocal_guardian)
    assert_difference("Service.count") do
      post services_url, params: {
        service: { full_name: "Test User", due_date: Date.current, guard_id: guards(:one).id }
      }
    end
    assert_redirected_to service_url(Service.last)
  end

  test "create allowed for super_admin" do
    sign_in users(:super_admin)
    assert_difference("Service.count") do
      post services_url, params: {
        service: { full_name: "Test User", due_date: Date.current, guard_id: guards(:one).id }
      }
    end
    assert_redirected_to service_url(Service.last)
  end

  test "create allowed for any vocal user" do
    sign_in users(:unrelated_vocal)
    assert_difference("Service.count") do
      post services_url, params: {
        service: { full_name: "Test User", due_date: Date.current, guard_id: guards(:one).id }
      }
    end
    assert_redirected_to service_url(Service.unscoped.last)
  end

  test "create forbidden for non-vocal user unrelated to the guard" do
    sign_in users(:two)
    assert_no_difference("Service.count") do
      post services_url, params: {
        service: { full_name: "Test User", due_date: Date.current, guard_id: guards(:one).id }
      }
    end
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Policy tests for edit
  # ---------------------------------------------------------------------------

  test "edit allowed for vocal of the guard" do
    get edit_service_url(@service)
    assert_response :success
  end

  test "edit allowed for guardian of the guard" do
    sign_in users(:vocal_guardian)
    get edit_service_url(@service)
    assert_response :success
  end

  test "edit allowed for super_admin" do
    sign_in users(:super_admin)
    get edit_service_url(@service)
    assert_response :success
  end

  test "edit allowed for any vocal user" do
    sign_in users(:unrelated_vocal)
    get edit_service_url(@service)
    assert_response :success
  end

  test "edit forbidden for non-vocal user unrelated to the guard" do
    sign_in users(:two)
    get edit_service_url(@service)
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Policy tests for update
  # ---------------------------------------------------------------------------

  test "update allowed for vocal of the guard" do
    patch service_url(@service), params: { service: { full_name: "Updated" } }
    assert_redirected_to service_url(@service)
  end

  test "update allowed for guardian of the guard" do
    sign_in users(:vocal_guardian)
    patch service_url(@service), params: { service: { full_name: "Updated" } }
    assert_redirected_to service_url(@service)
  end

  test "update allowed for super_admin" do
    sign_in users(:super_admin)
    patch service_url(@service), params: { service: { full_name: "Updated" } }
    assert_redirected_to service_url(@service)
  end

  test "update allowed for any vocal user" do
    sign_in users(:unrelated_vocal)
    patch service_url(@service), params: { service: { full_name: "Updated" } }
    assert_redirected_to service_url(@service)
  end

  test "update forbidden for non-vocal user unrelated to the guard" do
    sign_in users(:two)
    patch service_url(@service), params: { service: { full_name: "Updated" } }
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Policy tests for destroy
  # ---------------------------------------------------------------------------

  test "destroy allowed for vocal of the guard" do
    assert_difference("Service.count", -1) do
      delete service_url(@service)
    end
    assert_redirected_to services_url
  end

  test "destroy allowed for guardian of the guard" do
    sign_in users(:vocal_guardian)
    assert_difference("Service.count", -1) do
      delete service_url(@service)
    end
    assert_redirected_to services_url
  end

  test "destroy allowed for super_admin" do
    sign_in users(:super_admin)
    assert_difference("Service.count", -1) do
      delete service_url(@service)
    end
    assert_redirected_to services_url
  end

  test "destroy allowed for any vocal user" do
    sign_in users(:unrelated_vocal)
    assert_difference("Service.count", -1) do
      delete service_url(@service)
    end
    assert_redirected_to services_url
  end

  test "destroy forbidden for non-vocal user unrelated to the guard" do
    sign_in users(:two)
    assert_no_difference("Service.count") do
      delete service_url(@service)
    end
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Change history (PaperTrail)
  # ---------------------------------------------------------------------------

  test "update records who made the change" do
    sign_in users(:super_admin)
    patch service_url(@service), params: { service: { full_name: "Cambio Auditado" } }

    assert_equal users(:super_admin).id.to_s, @service.versions.last.whodunnit
  end

  test "history is shown to super_admin with the recorded changes" do
    sign_in users(:super_admin)
    patch service_url(@service), params: { service: { full_name: "Cambio Auditado" } }

    get history_service_url(@service)

    assert_response :success
    assert_select "dd span", text: "Cambio Auditado"
    assert_select "dt", text: Service.human_attribute_name(:full_name)
    assert_select "span", text: /#{users(:super_admin).full_name}/
  end

  test "history highlights status changes" do
    sign_in users(:super_admin)
    post complete_service_url(@service)

    get history_service_url(@service)

    assert_select "dl div.border-indigo-400" do
      assert_select "dt", text: /#{Service.human_attribute_name(:status)}/
      assert_select "span.badge_red", text: I18n.t("services.status.pending")
      assert_select "span.badge_green", text: I18n.t("services.status.completed")
    end
  end

  test "history is forbidden for non super_admin users" do
    get history_service_url(@service)
    assert_redirected_to root_path
  end

  test "show displays the history button only to super_admin" do
    get service_url(@service)
    assert_select "a[href='#{history_service_path(@service)}']", count: 0

    sign_in users(:super_admin)
    get service_url(@service)
    assert_select "a[href='#{history_service_path(@service)}']"
  end

  test "history button shows the number of recorded changes" do
    sign_in users(:super_admin)
    2.times { |i| patch service_url(@service), params: { service: { full_name: "Cambio #{i}" } } }

    get service_url(@service)

    assert_select "a[href='#{history_service_path(@service)}'] span", text: "2"
  end

  test "changes made while impersonating are recorded under the real super_admin" do
    sign_in users(:super_admin)
    post impersonate_user_url(users(:one))

    patch service_url(@service), params: { service: { full_name: "Cambio Suplantado" } }

    assert_equal "Cambio Suplantado", @service.reload.full_name
    assert_equal users(:super_admin).id.to_s, @service.versions.last.whodunnit
  end

  test "history shows a guard change with readable guard labels" do
    sign_in users(:super_admin)
    other_open = Guard.create!(day_number: 2, due_date: Date.new(2026, 3, 2), status: :open,
                               vocal: users(:one), priest: users(:two), guard_setup: guard_setups(:one), guardians: [ users(:one) ])
    patch service_url(@service), params: { service: { guard_id: other_open.id } }

    get history_service_url(@service)

    assert_select "dd span", text: "##{guards(:one).day_number} – #{I18n.l(guards(:one).due_date, format: :long)}"
    assert_select "dd span", text: "#2 – #{I18n.l(other_open.due_date, format: :long)}"
  end

  test "history shows an empty state when nothing was recorded" do
    sign_in users(:super_admin)
    get history_service_url(@service)

    assert_response :success
    assert_select "p", text: I18n.t("history.empty")
  end

  # ---------------------------------------------------------------------------
  # Comments (Lexxy rich text)
  # ---------------------------------------------------------------------------

  test "edit renders the comments field as a Lexxy editor without attachments" do
    @service.update!(comments: "<p>Llamar antes de ir</p>")

    get edit_service_url(@service)

    # The lexxy-content class makes Lexxy's text styles (strikethrough, underline, headings…) apply inside the editor.
    assert_select "lexxy-editor.lexxy-content[name='service[comments]'][attachments='false']" do |editors|
      assert_equal "<p>Llamar antes de ir</p>", editors.first["value"]
    end
    assert_select "textarea[name='service[comments]']", count: 0
  end

  test "update saves rich text comments" do
    patch service_url(@service), params: { service: { comments: "<p>Paciente en <strong>sala 3</strong></p>" } }

    assert_redirected_to service_url(@service)
    assert_equal "<p>Paciente en <strong>sala 3</strong></p>", @service.reload.comments
  end

  test "show renders rich text comments sanitized" do
    @service.update!(comments: %(<p>Paciente en <strong>sala 3</strong></p><script>alert("x")</script>))

    get service_url(@service)

    assert_select ".lexxy-content strong", text: "sala 3"
    assert_select ".lexxy-content script", count: 0
  end

  test "show keeps Lexxy highlight colors in comments" do
    @service.update!(comments: %(<p><mark style="color: var(--highlight-2);">urgente</mark></p>))

    get service_url(@service)

    assert_select ".lexxy-content mark[style='color: var(--highlight-2);']", text: "urgente"
  end

  test "show keeps line breaks of plain text comments" do
    @service.update!(comments: "Primera línea\nSegunda línea")

    get service_url(@service)

    assert_select ".lexxy-content p br"
  end
end
