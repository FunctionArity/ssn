module ApplicationHelper
  def user_crown_icon(user = current_user)
    return if user&.regular?
    return tag.i class: "ph ph-crown-simple" if user&.admin?

    tag.i class: "ph ph-crown" if user&.super_admin?
  end

  # Text from the Lexxy editor is sanitized HTML; older plain text keeps its line breaks.
  def rich_text_html(text)
    return if text.blank?

    text.match?(/<[a-z][^>]*>/i) ? sanitize(text, scrubber: RichTextScrubber.new) : simple_format(text, {}, wrapper_tag: "p")
  end

  # The same text without markup, for plain text like the clipboard: paragraphs and line breaks become new lines,
  # and list items start with a bullet.
  def rich_text_plain(text)
    return if text.blank?
    return text unless text.match?(/<[a-z][^>]*>/i)

    fragment = Nokogiri::HTML5.fragment(text)
    fragment.css("br").each { |br| br.replace("\n") }
    fragment.css("li").each { |item| item.prepend_child("• ") }
    fragment.css("p, div, blockquote, li, h1, h2, h3, h4, h5, h6, pre").each { |block| block.add_next_sibling("\n") }
    fragment.text.lines.map(&:strip).join("\n").gsub(/\n{3,}/, "\n\n").strip.presence
  end

  def setup_active?
    setup_paths = %w[/guard_setups /priest_setups /users /health_facilities /churches /headquarters]
    setup_paths.any? { |path| request.path.start_with?(path) }
  end
end
