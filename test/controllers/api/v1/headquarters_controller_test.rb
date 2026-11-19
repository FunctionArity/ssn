require "test_helper"

class Api::V1::HeadquartersControllerTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  test "lists the sedes" do
    get api_v1_headquarters_url, headers: api_headers(users(:super_admin)), as: :json

    assert_response :success
    assert_equal %w[Mendoza Quito], json["headquarters"].map { it["city"] }.sort
  end
end
