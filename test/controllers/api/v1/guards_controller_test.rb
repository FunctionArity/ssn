require "test_helper"

class Api::V1::GuardsControllerTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  setup do
    @quito = headquarters(:two)
    ActsAsTenant.with_tenant(@quito) do
      vocal = User.create!(email: "vocal@quito.test", first_name: "Ana", last_name: "Quiteña", role: :vocal, password: "password123")
      priest = User.create!(email: "priest@quito.test", first_name: "Luis", last_name: "Quiteño", role: :priest, password: "password123")
      setup = GuardSetup.create!(day_number: 1, vocal: vocal, guardian_ids: [ vocal.id ])
      @quito_guard = Guard.create!(guard_setup: setup, day_number: 1, due_date: Date.current, vocal: vocal, priest: priest, guardian_ids: [ vocal.id ])
    end
  end

  test "lists the sede's guards, newest first, with their people and number of services" do
    get api_v1_guards_url, headers: api_headers(users(:one)), as: :json

    assert_response :success
    guard = json["guards"].find { it["id"] == guards(:one).id }
    assert_equal "2026-03-01", guard["due_date"]
    assert_equal "Rodriguez Pablo", guard.dig("vocal", "full_name")
    assert_equal users(:two).id, guard.dig("priest", "id")
    assert_equal [ users(:vocal_guardian).id, users(:one).id ].sort, guard["guardians"].map { it["id"] }.sort
    assert_equal guards(:one).services.count, guard["services_count"]
    assert_not_includes json["guards"].map { it["id"] }, @quito_guard.id
    assert_equal 1, json["page"]
  end

  test "includes today's guard setup when today has no guard yet" do
    travel_to Date.new(2026, 11, 20) do
      get api_v1_guards_url, headers: api_headers(users(:one)), as: :json
    end

    assert_response :success
    assert_equal guard_setups(:two).id, json.dig("today_guard_setup", "id")
    assert_equal users(:vocal_guardian).id, json.dig("today_guard_setup", "vocal", "id")
  end

  test "has no guard setup for today when there's no setup for today's day" do
    travel_to Date.new(2026, 11, 19) do
      get api_v1_guards_url, headers: api_headers(users(:one)), as: :json
    end

    assert_response :success
    assert json.key?("today_guard_setup")
    assert_nil json["today_guard_setup"]
  end

  test "pages the list" do
    get api_v1_guards_url(page: 99), headers: api_headers(users(:one)), as: :json

    assert_equal json["total_pages"], json["page"]
  end

  test "shows a guard with its services in order" do
    get api_v1_guard_url(guards(:one)), headers: api_headers(users(:one)), as: :json

    assert_response :success
    assert_equal guards(:one).number, json.dig("guard", "number")
    assert_equal guards(:one).services.order(:position).pluck(:full_name), json.dig("guard", "services").map { it["full_name"] }
  end

  test "doesn't show another sede's guard" do
    get api_v1_guard_url(@quito_guard), headers: api_headers(users(:super_admin)), as: :json

    assert_response :not_found
    assert_equal I18n.t("api.errors.not_found"), json["error"]
  end

  test "super admins see the guards of the sede they switched to" do
    headers = api_headers(users(:super_admin), headquarter: @quito)

    get api_v1_guards_url, headers: headers, as: :json
    assert_equal [ @quito_guard.id ], json["guards"].map { it["id"] }

    get api_v1_guard_url(@quito_guard), headers: headers, as: :json
    assert_response :success
  end
end
