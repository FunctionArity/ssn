require "test_helper"

class RichTextScrubberTest < ActiveSupport::TestCase
  def sanitize(html)
    ActionController::Base.helpers.sanitize(html, scrubber: RichTextScrubber.new)
  end

  test "keeps Lexxy highlight styles" do
    html = %(<mark style="color: var(--highlight-2);">a</mark><mark style="background-color: var(--highlight-bg-3);">b</mark>)

    assert_equal html, sanitize(html)
  end

  test "removes any other inline style" do
    assert_equal "<p>x</p>", sanitize(%(<p style="color: red">x</p>))
    assert_equal "<mark>x</mark>", sanitize(%(<mark style="background:url(javascript:alert(1)); color: var(--highlight-2)">x</mark>))
  end

  test "keeps formatting tags and removes scripts, event handlers and javascript links" do
    result = sanitize(%(<h2>T</h2><p onclick="alert(1)"><strong>b</strong> <em>i</em></p><script>alert(1)</script><a href="javascript:alert(1)">l</a>))

    assert_equal "<h2>T</h2><p><strong>b</strong> <em>i</em></p>alert(1)<a>l</a>", result
  end
end
