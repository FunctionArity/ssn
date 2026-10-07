xml.instruct!
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  xml.url do
    xml.loc root_url
    xml.changefreq "weekly"
    xml.priority "1.0"
  end

  xml.url do
    xml.loc sedes_url
    xml.changefreq "weekly"
    xml.priority "0.8"
  end

  xml.url do
    xml.loc federacion_url
    xml.changefreq "monthly"
    xml.priority "0.5"
  end

  @headquarters.each do |headquarter|
    xml.url do
      xml.loc sede_url(headquarter)
      xml.changefreq "monthly"
      xml.priority "0.6"
    end
  end
end
