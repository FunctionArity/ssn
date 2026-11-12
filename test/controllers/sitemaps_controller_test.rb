require "test_helper"

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  SITEMAP_NAMESPACE = { "s" => "http://www.sitemaps.org/schemas/sitemap/0.9" }.freeze

  test "is public and served as XML" do
    get sitemap_url

    assert_response :success
    assert_equal "application/xml", response.media_type
    assert response.body.start_with?('<?xml version="1.0" encoding="UTF-8"?>')
  end

  test "lists the public pages with how often they change and their priority" do
    get sitemap_url

    entries = sitemap_entries
    assert_equal [ "weekly", "1.0" ], entries[root_url]
    assert_equal [ "weekly", "0.8" ], entries[sedes_url]
    assert_equal [ "monthly", "0.7" ], entries[federacion_url]
    assert_equal [ "monthly", "0.5" ], entries[asamblea2026_url]
  end

  test "lists every sede's page, ordered by country, state and city" do
    rosario = Headquarter.create!(country: "Argentina", state: "Santa Fe", city: "Rosario", address: "Córdoba 1000", phone: "341 555 1234")

    get sitemap_url

    sede_entries = sitemap_entries.select { |loc, _| loc.start_with?("#{sedes_url}/") }
    assert_equal [ headquarters(:one), rosario, headquarters(:two) ].map { |headquarter| sede_url(headquarter) }, sede_entries.keys
    assert sede_entries.values.all?([ "monthly", "0.6" ])
  end

  test "lists every sede to signed-in users too, whatever their sede" do
    sign_in users(:one)

    get sitemap_url

    assert_includes sitemap_entries.keys, sede_url(headquarters(:two))
  end

  private

  # Each URL of the sitemap, in order, with its [changefreq, priority].
  def sitemap_entries
    Nokogiri::XML(response.body).xpath("/s:urlset/s:url", SITEMAP_NAMESPACE).to_h do |url|
      %w[loc changefreq priority].map { |field| url.at_xpath("s:#{field}", SITEMAP_NAMESPACE).text }.then { |loc, *rest| [ loc, rest ] }
    end
  end
end
