# Emoji reactions to a comment, nested under it, e.g. POST /services/1/comments/2/reactions.
class CommentReactionsController < ApplicationController
  before_action :set_comment

  # Reacting again with the same emoji takes the reaction back.
  def create
    authorize @comment, :react?
    return head :unprocessable_entity unless toggle(params.expect(:emoji))

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(helpers.dom_id(@comment, :reactions),
                                                  partial: "comments/reactions", locals: { comment: @comment })
      end
      format.html { redirect_to polymorphic_path(@commentable, anchor: helpers.dom_id(@comment)) }
    end
  end

  private

  # False when the emoji isn't one users can pick.
  def toggle(emoji)
    reaction = @comment.reactions.find_by(user: current_user, emoji:)
    return reaction.destroy! if reaction

    @comment.reactions.create(user: current_user, emoji:).persisted?
  rescue ActiveRecord::RecordNotUnique
    true # A double click already saved it.
  end

  def set_comment
    param, model = CommentsController::COMMENTABLES.find { |key, _model| params.key?(key) }
    @commentable = model.find(params[param])
    @comment = @commentable.comments.find(params.expect(:comment_id))
  end
end
