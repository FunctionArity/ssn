module CommentsHelper
  # The comment's body, with the mentions of users who haven't read it yet marked.
  def comment_body_html(comment)
    html = rich_text_html(comment.body)
    unread_user_ids = comment.mentions.select(&:unread?).map(&:user_id)
    return html if html.blank? || unread_user_ids.empty?

    fragment = Nokogiri::HTML5.fragment(html)
    fragment.css("a[href]").each do |link|
      next unless unread_user_ids.include?(link["href"][Mentions::HREF, 1].to_i)

      link["class"] = "mention-unread"
      link.add_child(tag.i(class: "ph ph-eye-slash", title: t("comments.comment.mention_unread"), aria: { label: t("comments.comment.mention_unread") }))
    end
    fragment.to_html.html_safe # rubocop:disable Rails/OutputSafety -- already sanitized by rich_text_html
  end
end
