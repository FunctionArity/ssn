require "test_helper"

# The churches and health facilities lists, which everyone signed in can read.
class Api::V1::CatalogsControllerTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  test "lists the sede's churches by name" do
    get api_v1_churches_url, headers: api_headers(users(:two)), as: :json

    assert_response :success
    assert_equal [ "Cristo Rey", "Pquia. San Agustin" ], json["churches"].map { it["name"] }
  end

  test "lists the sede's health facilities by name" do
    get api_v1_health_facilities_url, headers: api_headers(users(:two)), as: :json

    assert_response :success
    assert_equal [ "Clínica Santa Rosa", "Hospital Central" ], json["health_facilities"].map { it["name"] }
  end

  test "filters health facilities by name from 3 characters" do
    get api_v1_health_facilities_url(q: "hosp"), headers: api_headers(users(:two)), as: :json
    assert_equal [ "Hospital Central" ], json["health_facilities"].map { it["name"] }

    get api_v1_health_facilities_url(q: "ho"), headers: api_headers(users(:two)), as: :json
    assert_equal 2, json["health_facilities"].size
  end

  test "another sede's lists are its own" do
    get api_v1_churches_url, headers: api_headers(users(:super_admin), headquarter: headquarters(:two)), as: :json

    assert_empty json["churches"]
  end
end
