# Comments of any Commentable record, nested under its route, e.g. /services/1/comments.
class CommentsController < ApplicationController
  # Parent models that can be commented, by their route param.
  COMMENTABLES = { service_id: Service }.freeze

  before_action :set_commentable

  def create
    @comment = @commentable.comments.build(body: params.dig(:comment, :body), user: current_user, parent: reply_parent)
    authorize @comment

    respond_to do |format|
      if @comment.save
        format.turbo_stream
        format.html { redirect_to polymorphic_path(@commentable, anchor: helpers.dom_id(@comment)) }
      else
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { redirect_to @commentable, alert: @comment.errors.full_messages.to_sentence }
      end
    end
  end

  def destroy
    authorize @comment
    had_replies = @comment.replies.exists?
    @comment.destroy!

    respond_to do |format|
      # Its replies become top-level comments, so the page reloads to show them in their new place.
      format.turbo_stream { render turbo_stream: had_replies ? turbo_stream.refresh(request_id: nil) : turbo_stream.remove(helpers.dom_id(@comment, :thread)) }
      format.html { redirect_to @commentable, status: :see_other }
    end
  end

  # Clicking an unread comment that mentions the current user marks it as read.
  def read
    # A comment that doesn't mention the user has nothing to mark.
    mention = current_user.comment_mentions.find_by(comment: @comment)
    if mention
      authorize mention
      # An admin impersonating someone shouldn't clear that user's unread comments.
      mention.read!
    else
      authorize @commentable, :comment?
    end

    render turbo_stream: [
      turbo_stream.replace(@comment, partial: "comments/entry", locals: { comment: @comment, unread: mention&.unread? || false }),
      turbo_stream.replace("mentions_indicator", partial: "layouts/mentions_indicator", locals: { user: current_user })
    ]
  end

  private

  def set_commentable
    param, model = COMMENTABLES.find { |key, _model| params.key?(key) }
    @commentable = model.find(params[param])
    # Create has no comment id; params.expect would reject it with 400 Bad Request.
    set_comment if params.key?(:id)
  end

  def set_comment
    @comment = @commentable.comments.find(params.expect(:id))
  end

  # The comment being replied to, which must belong to the same record.
  def reply_parent
    parent_id = params.dig(:comment, :parent_id).presence
    @commentable.comments.find(parent_id) if parent_id
  end
end
