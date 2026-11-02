# Helpers for rich text written in the Lexxy editor, where the @ prompt inserts a link to the mentioned user.
module Mentions
  HREF = %r{\A/users/(\d+)\z}

  module_function

  def user_ids(html)
    links(html).keys
  end

  # The mention links, as { user id => link text such as "@Name" }.
  def links(html)
    Nokogiri::HTML5.fragment(html.to_s).css("a[href]").each_with_object({}) do |link, links|
      id = link["href"][HREF, 1]&.to_i
      links[id] ||= link.text if id
    end
  end

  # Markup of the given mentions, as the editor's @ prompt inserts them.
  def to_html(links)
    links.map { |id, text| ActionController::Base.helpers.link_to(text, "/users/#{id}") }.join(" ")
  end

  # Links within the app, like the mentions, are relative and wouldn't work in an email, so they become plain bold text.
  def for_email(html)
    fragment = Nokogiri::HTML5.fragment(html.to_s)
    fragment.css("a[href^='/']").each do |link|
      link.name = "strong"
      link.remove_attribute("href")
    end
    fragment.to_html
  end

  # The text a reader sees, without markup, e.g. to measure its length.
  def text(html)
    CGI.unescapeHTML(ActionController::Base.helpers.strip_tags(html.to_s))
  end

  # The editor submits markup like "<p><br></p>" when it is empty.
  def blank?(html)
    ActionController::Base.helpers.strip_tags(html.to_s).gsub(/[[:space:]]|&nbsp;/, "").empty?
  end
end
