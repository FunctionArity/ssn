# Notifies a mentioned user on every browser and phone where they turned push notifications on.
class MentionPushJob < ApplicationJob
  queue_as :default

  # The mention is gone if the comment was deleted or edited to not mention them anymore.
  discard_on ActiveJob::DeserializationError

  def perform(mention)
    # Already read, e.g. in an open tab, by the time the job runs.
    return unless mention.unread? && PushSubscription.enabled?

    message = message_for(mention.comment)
    mention.user.push_subscriptions.each { |subscription| subscription.deliver(message) }
  end

  private

  def message_for(comment)
    commentable = comment.commentable
    scope = "push_notifications.mention"

    {
      title: I18n.t("#{scope}.title", author: comment.user.full_name),
      options: {
        body: I18n.t("#{scope}.body.#{commentable.model_name.i18n_key}", name: commentable.comment_subject,
                     text: plain_text(comment.body).truncate(140)),
        icon: "/icon-192.png",
        # Another notification for the same comment replaces this one.
        tag: ActionView::RecordIdentifier.dom_id(comment),
        # A button under the text, where the browser supports them (Chrome, Edge, Android).
        # Clicking anywhere on the notification opens the comment as well.
        actions: [ { action: "open", title: I18n.t("#{scope}.open") } ],
        data: { path: Rails.application.routes.url_helpers.polymorphic_path(commentable, anchor: ActionView::RecordIdentifier.dom_id(comment)) }
      }
    }
  end

  # Keeps a space between paragraphs and lines, which stripping the tags would glue together.
  def plain_text(html)
    Mentions.text(html.gsub(%r{</p>|<br\s*/?>}i, "\\0 ")).squish
  end
end
