module SeoHelper
  SITE_NAME = "Servicio Sacerdotal Nocturno".freeze

  def page_title
    title = content_for(:title)
    return SITE_NAME if title.blank?

    title.include?(SITE_NAME) ? title : safe_join([ title, SITE_NAME ], " · ")
  end

  def canonical_url
    content_for(:canonical).presence || "#{request.base_url}#{request.path}"
  end

  def og_image_url
    content_for(:og_image).presence || "#{request.base_url}/icon-512.png"
  end

  # ActiveSupport escapes <, > and & in JSON, so the payload can't close the script tag.
  def json_ld(data)
    tag.script(data.to_json.html_safe, type: "application/ld+json")
  end

  def organization_schema
    {
      "@type": "Organization",
      name: "Federación Argentina del Servicio Sacerdotal de Urgencia y Nocturno",
      alternateName: [ "FSSUN", SITE_NAME ],
      url: root_url,
      logo: image_url("fassnu-logo.jpg"),
      foundingDate: "1952",
      areaServed: { "@type": "Country", name: "Argentina" }
    }
  end

  def headquarter_schema(headquarter)
    links = [ headquarter.web_address, headquarter.facebook, headquarter.instagram ].select { |url| url.to_s.start_with?("http") }

    {
      "@context": "https://schema.org",
      "@type": "Organization",
      name: "#{SITE_NAME} · #{headquarter.city}",
      url: sede_url(headquarter),
      address: {
        "@type": "PostalAddress",
        streetAddress: headquarter.address,
        addressLocality: headquarter.city,
        addressRegion: headquarter.state,
        addressCountry: headquarter.country
      },
      telephone: headquarter.phone.presence,
      email: headquarter.email.presence,
      sameAs: links.presence,
      parentOrganization: organization_schema.slice(:"@type", :name, :url)
    }.compact
  end
end
