require "test_helper"

class Doc::PrivacidadControllerTest < ActionDispatch::IntegrationTest
  test "shows the privacy policy without signing in" do
    get privacidad_url

    assert_response :success
    assert_select "h1", "Política de privacidad"
    assert_select "title", "Política de privacidad · Servicio Sacerdotal Nocturno"
    assert_select "link[rel=canonical][href=?]", privacidad_url
    assert_select "article a[href=?]", sedes_path
    assert_select "article a[href=?]", "mailto:info@serviciosacerdotalnocturno.org", text: "info@serviciosacerdotalnocturno.org"
  end

  test "the public pages and the sign-in page link to it" do
    get federacion_url
    assert_select "footer a[href=?]", privacidad_path, text: I18n.t("devise_views.shared.privacy_policy")

    get new_user_session_url
    assert_select "a[href=?]", privacidad_path, text: I18n.t("devise_views.shared.privacy_policy")
  end

  test "is in the sitemap" do
    get sitemap_url

    assert_includes response.body, "<loc>#{privacidad_url}</loc>"
  end
end
