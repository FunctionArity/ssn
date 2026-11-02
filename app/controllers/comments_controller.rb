# Comments of any Commentable record, nested under its route, e.g. /services/1/comments.
class CommentsController < ApplicationController
  # Parent models that can be commented, by their route param.
  COMMENTABLES = { service_id: Service }.freeze

  before_action :set_commentable

  def create
    @comment = @commentable.comments.build(body: params.dig(:comment, :body), user: current_user)
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
    @comment.destroy!

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@comment) }
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
      mention.read! if current_user == true_user
    else
      authorize @commentable, :comment?
    end

    render turbo_stream: [
      turbo_stream.replace(@comment, partial: "comments/comment", locals: { comment: @comment, unread: mention&.unread? || false }),
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
end
