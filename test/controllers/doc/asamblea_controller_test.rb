require "test_helper"

class Doc::AsambleaControllerTest < ActionDispatch::IntegrationTest
  test "should get index without authentication" do
    get asamblea2026_url
    assert_response :success
    assert_select "h1", I18n.t("doc.asamblea.index.title")
  end
end
