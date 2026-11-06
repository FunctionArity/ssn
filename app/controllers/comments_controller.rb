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

  # The comment as listed; cancelling an inline edit puts it back.
  def show
    authorize @comment

    respond_to do |format|
      format.turbo_stream { render turbo_stream: replace_entry }
      format.html { redirect_to polymorphic_path(@commentable, anchor: helpers.dom_id(@comment)) }
    end
  end

  # Swaps the comment for its inline edit form.
  def edit
    authorize @comment

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(@comment, partial: "comments/edit_form", locals: { comment: @comment }) }
      format.html { redirect_to polymorphic_path(@commentable, anchor: helpers.dom_id(@comment)) }
    end
  end

  def update
    authorize @comment

    respond_to do |format|
      if @comment.update(body: params.dig(:comment, :body))
        format.turbo_stream { render turbo_stream: replace_entry }
        format.html { redirect_to polymorphic_path(@commentable, anchor: helpers.dom_id(@comment)) }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@comment, partial: "comments/edit_form", locals: { comment: @comment }), status: :unprocessable_entity }
        format.html { redirect_to @commentable, alert: @comment.errors.full_messages.to_sentence }
      end
    end
  end

  def destroy
    authorize @comment
    @comment.destroy!

    respond_to do |format|
      format.turbo_stream do
        # Its replies are inside its thread, so they go away with it.
        streams = [ turbo_stream.remove(helpers.dom_id(@comment, :thread)) ]
        # A parent left without replies can be edited again, so its edit button comes back.
        # Loaded again: the parent's replies in memory still hold the deleted comment.
        parent = Comment.find_by(id: @comment.parent_id)
        if parent && parent.replies.none?
          streams << turbo_stream.replace(parent, partial: "comments/entry",
                                                  locals: { comment: parent, unread: current_user.comment_mentions.unread.exists?(comment: parent) })
        end
        render turbo_stream: streams
      end
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
      mention.read! if acting_as_self?
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

  def replace_entry
    unread = current_user.comment_mentions.unread.exists?(comment: @comment)
    turbo_stream.replace(@comment, partial: "comments/entry", locals: { comment: @comment, unread: unread })
  end

  # The comment being replied to, which must belong to the same record.
  def reply_parent
    parent_id = params.dig(:comment, :parent_id).presence
    @commentable.comments.find(parent_id) if parent_id
  end
end
