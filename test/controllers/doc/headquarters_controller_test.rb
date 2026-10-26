require "test_helper"

class Doc::HeadquartersControllerTest < ActionDispatch::IntegrationTest
  test "should get index without authentication" do
    get doc_headquarters_url
    assert_response :success
  end

  test "should list headquarters" do
    get doc_headquarters_url
    assert_select "[data-headquarters-filter-target=card]", Headquarter.count
  end

  test "should get show without authentication" do
    get sede_url(headquarters(:one))
    assert_response :success
  end

  test "index canonical points to sedes" do
    get doc_headquarters_url
    assert_select "link[rel=canonical][href=?]", sedes_url
    assert_select "meta[name=description][content=?]", I18n.t("doc.headquarters.index.description")
  end

  test "show renders canonical and headquarter schema" do
    headquarter = headquarters(:one)
    get sede_url(headquarter.id)
    assert_select "link[rel=canonical][href=?]", sede_url(headquarter)

    schema = JSON.parse(css_select("script[type='application/ld+json']").first.text)
    assert_equal "Organization", schema["@type"]
    assert_equal headquarter.city, schema.dig("address", "addressLocality")
  end
end
