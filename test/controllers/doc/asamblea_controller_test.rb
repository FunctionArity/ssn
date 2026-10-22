require "test_helper"

class Doc::AsambleaControllerTest < ActionDispatch::IntegrationTest
  test "should get index without authentication" do
    get asamblea2026_url
    assert_response :success
    assert_select "h1", I18n.t("doc.asamblea.index.title")
  end

  test "should render SEO tags and Event schema" do
    get asamblea2026_url
    assert_select "html[lang=es]"
    assert_select "title", "#{I18n.t("doc.asamblea.index.page_title")} · Servicio Sacerdotal Nocturno"
    assert_select "meta[name=description][content=?]", I18n.t("doc.asamblea.index.description")
    assert_select "link[rel=canonical][href=?]", asamblea2026_url
    assert_select "meta[property='og:title']"

    schema = JSON.parse(css_select("script[type='application/ld+json']").first.text)
    assert_equal "Event", schema["@type"]
    assert_equal "Lunlunta", schema.dig("location", "address", "addressLocality")
  end
end
