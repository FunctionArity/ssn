require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "rich_text_plain turns paragraphs and line breaks into new lines" do
    assert_equal "Hablar con Pepe\nConfirmar\nantes de ir", rich_text_plain("<p>Hablar con <strong>Pepe</strong></p><p>Confirmar<br>antes de ir</p>")
  end

  test "rich_text_plain keeps one blank line for empty paragraphs and quotes" do
    html = %(<p><mark style="color: var(--highlight-4);"><strong>Hablar con pepe</strong></mark></p><p><br></p><blockquote><p><em>Confirmar antes de ir</em></p></blockquote>)

    assert_equal "Hablar con pepe\n\nConfirmar antes de ir", rich_text_plain(html)
  end

  test "rich_text_plain starts list items with a bullet and decodes entities" do
    assert_equal "Llevar:\n• Óleo &\n• Estola", rich_text_plain("<p>Llevar:</p><ul><li>Óleo &amp;</li><li>Estola</li></ul>")
  end

  test "rich_text_plain leaves plain text as it is" do
    assert_equal "no se pudo realizar, llamar mañana", rich_text_plain("no se pudo realizar, llamar mañana")
    assert_nil rich_text_plain(nil)
    assert_nil rich_text_plain("<p><br></p>")
  end
end
