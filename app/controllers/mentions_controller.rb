# The comments where the current user was mentioned, behind the bell in the top nav.
class MentionsController < ApplicationController
  LIMIT = 50

  def index
    @mentions = current_user.recent_mentions.limit(LIMIT)
  end

  def read_all
    # An admin impersonating someone shouldn't clear that user's unread comments.
    if acting_as_self?
      current_user.unread_mentions.update_all(read_at: Time.current, updated_at: Time.current)
      CommentMention.broadcast_unread_count(current_user)
    end

    redirect_to mentions_path, status: :see_other
  end
end
