# Sanitizes rich text from the Lexxy editor: Rails' safe list of tags and attributes, plus the
# inline styles Lexxy writes for highlights (e.g. <mark style="color: var(--highlight-2);">).
# Any other style is removed, since Rails' CSS sanitizer would strip the var() values anyway.
class RichTextScrubber < Rails::HTML::PermitScrubber
  HIGHLIGHT_STYLE = /\A(\s*(?:background-)?color:\s*var\(--highlight(?:-bg)?-\d+\)\s*;?)+\s*\z/

  def initialize
    super
    self.tags = Rails::HTML5::SafeListSanitizer.allowed_tags.to_a | %w[mark]
    self.attributes = Rails::HTML5::SafeListSanitizer.allowed_attributes.to_a | %w[style]
  end

  protected

  def scrub_css_attribute(node)
    style = node.attributes["style"]
    style.remove if style && !style.value.match?(HIGHLIGHT_STYLE)
  end
end
