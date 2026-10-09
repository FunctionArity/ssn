require "test_helper"

class Doc::FederacionControllerTest < ActionDispatch::IntegrationTest
  test "should get index without authentication" do
    get federacion_url
    assert_response :success
    assert_select "h1", /Federación Argentina del Servicio Sacerdotal de Urgencia y Nocturno/
  end

  test "lists every headquarter linking to its public page" do
    get federacion_url
    Headquarter.find_each do |headquarter|
      assert_select "a[href='#{sede_path(headquarter)}']"
    end
  end

  test "contact section has call buttons for the national commission" do
    get federacion_url
    assert_select "a[href='tel:+5492612069195']", text: /Llamar/
    assert_select "a[href='tel:+5492617539095']", text: /Llamar/
    assert_select "a[href='tel:+5492614708686']", text: /Llamar/
    assert_select "a[href*='sites.google.com']", count: 0
    assert_select "section:has(#contacto) a[href='#{sedes_path}']"
  end

  test "each section heading links to its previous and next section" do
    get federacion_url
    ids = Doc::FederacionController::SECTIONS.map(&:first)

    assert_select "h2##{ids.first} + div a[aria-label^='Sección anterior']", count: 0
    assert_select "h2##{ids.last} + div a[aria-label^='Sección siguiente']", count: 0
    assert_select "a[aria-label^='Sección siguiente'][href='##{ids.second}']"
    assert_select "a[aria-label^='Sección anterior'][href='##{ids[-2]}']"
    assert_select "a[aria-label^='Sección siguiente']", count: ids.size - 1
    assert_select "a[aria-label^='Sección anterior']", count: ids.size - 1
  end

  test "navbar links to federacion and asamblea" do
    get federacion_url
    assert_select "nav a[href='#{federacion_path}']"
    assert_select "nav a[href='#{asamblea2026_path}']"
  end

  test "table of contents links to the 2026 assembly" do
    get federacion_url
    assert_select "nav:has(a[data-scroll-spy-target]) a[href='#{asamblea2026_path}']", text: /Asamblea 2026/
  end
end
