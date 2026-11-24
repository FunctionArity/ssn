require "test_helper"

class LocaleTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  test "shows Spanish by default" do
    get new_user_session_url

    assert_select "html[lang=es]"
    assert_select "a[href=?]", "#{new_user_session_path}?locale=en", text: "EN"
  end

  test "switches to English with ?locale=en and remembers it" do
    get new_user_session_url(locale: :en)
    assert_select "html[lang=en]"
    assert_select "a[href=?]", "#{new_user_session_path}?locale=es", text: "ES"

    get new_user_session_url
    assert_select "html[lang=en]"
    assert_select "a", text: I18n.t("devise_views.shared.privacy_policy", locale: :en)
  end

  test "switches back to Spanish" do
    get new_user_session_url(locale: :en)
    get new_user_session_url(locale: :es)

    assert_select "html[lang=es]"
  end

  test "ignores a language it doesn't have" do
    get new_user_session_url(locale: :fr)

    assert_select "html[lang=es]"
    assert_nil cookies[:locale].presence
  end

  test "the signed-in app shows the switch, keeps the other query parameters and stays in English after signing out" do
    sign_in users(:one)

    get root_url(locale: :en)
    assert_select "html[lang=en]"
    assert_select "p", text: I18n.t("home.dashboard.quick_access", locale: :en)
    assert_select "a[href=?]", "/?locale=es", text: "ES"

    get services_url(full_name: "Ana", locale: :en)
    assert_select "a[href=?]", "#{services_path}?full_name=Ana&locale=es"

    delete destroy_user_session_url
    get new_user_session_url
    assert_select "html[lang=en]"
  end
end
