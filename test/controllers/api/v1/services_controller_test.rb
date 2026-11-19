require "test_helper"

class Api::V1::ServicesControllerTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  test "lists today's guard and its services" do
    travel_to guards(:one).due_date do
      get api_v1_services_url, headers: api_headers(users(:one)), as: :json
    end

    assert_response :success
    assert_equal guards(:one).id, json.dig("current_guard", "id")
    assert_equal guards(:one).services.order(:position).pluck(:id), json["services"].map { it["id"] }
    assert_equal "Rodriguez Pablo", json["services"].first.dig("created_by", "full_name")
  end

  test "without a guard today, lists the pending services of other guards" do
    travel_to guards(:one).due_date + 1.day do
      get api_v1_services_url, headers: api_headers(users(:one)), as: :json
    end

    assert_nil json["current_guard"]
    assert_empty json["services"]
    pending = json["pending_other_services"]
    assert_includes pending.map { it["id"] }, services(:one).id
    assert_not_includes pending.map { it["id"] }, services(:completed_one).id
    assert_equal "2026-03-01", pending.find { it["id"] == services(:one).id }["guard_due_date"]
  end

  test "searches by name" do
    get api_v1_services_url(full_name: " juan perez "), headers: api_headers(users(:one)), as: :json

    assert_equal({ "full_name" => "juan perez" }, json["filters"])
    assert_equal [ services(:one).id ], json["results"].map { it["id"] }
    assert_equal 1, json["results_count"]
  end

  test "shows a service with its details and guard" do
    get api_v1_service_url(services(:one)), headers: api_headers(users(:one)), as: :json

    assert_response :success
    service = json["service"]
    assert_equal "Juan Pérez", service["full_name"]
    assert_equal guards(:one).id, service.dig("guard", "id")
    assert_equal services(:one).comments.count, service["comments_count"]
  end

  test "doesn't show another sede's service" do
    service = ActsAsTenant.with_tenant(headquarters(:two)) do
      vocal = User.create!(email: "vocal@quito.test", first_name: "Ana", last_name: "Quiteña", role: :vocal, password: "password123")
      setup = GuardSetup.create!(day_number: 1, vocal: vocal, guardian_ids: [ vocal.id ])
      guard = Guard.create!(guard_setup: setup, day_number: 1, due_date: Date.current, vocal: vocal, priest: vocal, guardian_ids: [ vocal.id ])
      guard.services.create!(full_name: "Servicio Quiteño", due_date: Date.current, created_by: vocal)
    end

    get api_v1_service_url(service), headers: api_headers(users(:one)), as: :json

    assert_response :not_found
  end
end
