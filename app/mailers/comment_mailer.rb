class CommentMailer < ApplicationMailer
  helper :application

  def mention
    @comment = params[:comment]
    @commentable = @comment.commentable
    @author = @comment.user
    @body = Mentions.for_email(@comment.body)
    @scope = "comment_mailer.mention.#{@commentable.model_name.i18n_key}"

    mail to: params[:user].email, subject: t("#{@scope}.subject", name: @commentable.comment_subject)
  end
end
