require "test_helper"

class Doc::ApiControllerTest < ActionDispatch::IntegrationTest
  test "shows the API docs without signing in" do
    get api_docs_url

    assert_response :success
    assert_select "title", "Documentación de la API · Servicio Sacerdotal Nocturno"
    assert_select "link[rel=canonical][href=?]", api_docs_url
    assert_select "#api-docs"
    assert_select "script[src^='https://cdn.jsdelivr.net/npm/@scalar/api-reference@']"
    assert_includes response.body, %(url: "#{api_spec_path}")
  end

  test "serves the spec as JSON without signing in, with the YAML merge keys resolved" do
    get api_spec_url

    assert_response :success
    assert_equal "application/json", response.media_type
    spec = response.parsed_body
    assert_equal "3.0.3", spec["openapi"]
    assert_includes spec.dig("components", "schemas", "GuardSummary", "properties").keys, "due_date"
    assert_not_includes response.body, "<<"
  end

  test "documents every API route" do
    documented = Doc::ApiController.spec["paths"].flat_map { |path, operations| operations.keys.map { "#{it.upcase} #{path}" } }
    routes = Rails.application.routes.routes.filter_map do |route|
      path = route.path.spec.to_s.delete_suffix("(.:format)")
      "#{route.verb} #{path.gsub(/:(\w+)/, '{\1}')}" if path.start_with?("/api/v1/")
    end

    assert_empty routes.uniq - documented, "Add these API routes to config/openapi.yaml"
  end

  test "the public pages link to it and it's in the sitemap" do
    get federacion_url
    assert_select "footer a[href=?]", api_docs_path

    get sitemap_url
    assert_includes response.body, "<loc>#{api_docs_url}</loc>"
  end
end
