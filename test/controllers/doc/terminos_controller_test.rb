require "test_helper"

class Doc::TerminosControllerTest < ActionDispatch::IntegrationTest
  test "shows the terms without signing in" do
    get terminos_url

    assert_response :success
    assert_select "h1", "Términos y condiciones"
    assert_select "title", "Términos y condiciones · Servicio Sacerdotal Nocturno"
    assert_select "link[rel=canonical][href=?]", terminos_url
    assert_select "article a[href=?]", privacidad_path
    assert_select "article a[href=?]", sedes_path
    assert_select "article a[href=?]", "mailto:#{Doc::PrivacidadController::CONTACT_EMAIL}"
  end

  test "the public pages and the sign-in page link to it" do
    get federacion_url
    assert_select "footer a[href=?]", terminos_path, text: I18n.t("devise_views.shared.terms")

    get new_user_session_url
    assert_select "a[href=?]", terminos_path, text: I18n.t("devise_views.shared.terms")
  end

  test "is in the sitemap" do
    get sitemap_url

    assert_includes response.body, "<loc>#{terminos_url}</loc>"
  end
end
