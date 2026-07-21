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
end
