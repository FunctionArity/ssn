require "test_helper"

# The fixtures are the Mendoza sede's (headquarters(:one)); Quito (headquarters(:two)) gets its own guard and service.
class HeadquarterTenancyControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @quito = headquarters(:two)
    ActsAsTenant.with_tenant(@quito) do
      @quito_vocal = User.create!(email: "vocal@quito.test", first_name: "Ana", last_name: "Quiteña", role: :vocal, password: "password123")
      priest = User.create!(email: "priest@quito.test", first_name: "Luis", last_name: "Quiteño", role: :priest, password: "password123")
      setup = GuardSetup.create!(day_number: 1, vocal: @quito_vocal, guardian_ids: [ @quito_vocal.id ])
      @quito_guard = Guard.create!(guard_setup: setup, day_number: 1, due_date: Date.current, vocal: @quito_vocal, priest: priest, guardian_ids: [ @quito_vocal.id ])
      @quito_service = @quito_guard.services.create!(full_name: "Servicio Quiteño", due_date: Date.current, created_by: @quito_vocal)
    end
  end

  test "users only see their sede's records" do
    sign_in users(:super_admin)

    get guards_url
    assert_response :success
    assert_select "a[href=?]", guard_path(guards(:one))
    assert_select "a[href=?]", guard_path(@quito_guard), count: 0

    get service_url(@quito_service)
    assert_response :not_found

    get guard_url(@quito_guard)
    assert_response :not_found
  end

  test "the health facilities list only has the sede's facilities" do
    quito_facility = ActsAsTenant.with_tenant(@quito) { HealthFacility.create!(name: "Hospital Eugenio Espejo", address: "Av. Gran Colombia, Quito") }
    sign_in users(:super_admin)

    get health_facilities_url
    assert_select "a[href=?]", health_facility_path(health_facilities(:one))
    assert_select "a[href=?]", health_facility_path(quito_facility), count: 0

    patch current_headquarter_url, params: { headquarter_id: @quito.id }
    get health_facilities_url
    assert_select "a[href=?]", health_facility_path(quito_facility)
    assert_select "a[href=?]", health_facility_path(health_facilities(:one)), count: 0
  end

  test "the users list only has the sede's users" do
    sign_in users(:super_admin)

    get users_url

    assert_response :success
    assert_select "a[href='#{user_path(users(:one))}']"
    assert_select "a[href='#{user_path(@quito_vocal)}']", count: 0
  end

  test "an invited user joins the inviter's sede" do
    sign_in users(:super_admin)

    post users_url, params: { user: { email: "invited@example.test", first_name: "New", last_name: "User", phone: "1111111111" } }

    assert_equal headquarters(:one), User.unscoped.find_by!(email: "invited@example.test").headquarter
  end

  test "a super admin switches to another sede" do
    sign_in users(:super_admin)

    patch current_headquarter_url, params: { headquarter_id: @quito.id }
    assert_redirected_to root_url
    assert_equal I18n.t("current_headquarters.notices.switched", name: @quito.city), flash[:notice]

    get guards_url
    assert_select "a[href=?]", guard_path(@quito_guard)
    assert_select "a[href=?]", guard_path(guards(:one)), count: 0
    assert_select "#headquarter_switcher button", text: @quito.city

    get service_url(@quito_service)
    assert_response :success

    post users_url, params: { user: { email: "quito.invited@example.test", first_name: "New", last_name: "User", phone: "1111111111" } }
    assert_equal @quito, User.unscoped.find_by!(email: "quito.invited@example.test").headquarter
  end

  test "a super admin creates services in the sede they switched to" do
    sign_in users(:super_admin)
    patch current_headquarter_url, params: { headquarter_id: @quito.id }

    assert_difference -> { ActsAsTenant.with_tenant(@quito) { Service.count } } do
      post services_url, params: { service: { full_name: "Otro Servicio Quiteño", due_date: Date.current, guard_id: @quito_guard.id } }
    end
  end

  test "other users can't switch sedes" do
    sign_in users(:admin_user)

    patch current_headquarter_url, params: { headquarter_id: @quito.id }
    assert_redirected_to root_url
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]

    get guards_url
    assert_select "a[href=?]", guard_path(guards(:one))
    assert_select "#headquarter_switcher", count: 0
    assert_select "aside [title=?]", I18n.t("sidebar.headquarter"), count: 0
  end

  test "a super admin impersonates the users of the sede they switched to" do
    sign_in users(:super_admin)
    patch current_headquarter_url, params: { headquarter_id: @quito.id }

    post impersonate_user_url(users(:one))
    assert_response :not_found

    post impersonate_user_url(@quito_vocal)
    get guards_url
    assert_select "a[href=?]", guard_path(@quito_guard)

    post stop_impersonating_url
    get guards_url
    assert_select "a[href=?]", guard_path(@quito_guard)
  end

  test "service changes are broadcast to the sede's stream" do
    sign_in users(:one)
    service = services(:one)

    assert_turbo_stream_broadcasts [ headquarters(:one), :services ], count: 1 do
      perform_enqueued_jobs do
        patch service_url(service), params: { service: { full_name: "Nombre Actualizado" } }
      end
    end
  end
end
