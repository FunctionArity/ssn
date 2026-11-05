require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  TURBO_STREAM = { "Accept" => "text/vnd.turbo-stream.html" }.freeze

  setup do
    @service = services(:one)
    @author = users(:one)
    @mentioned = users(:vocal_guardian)
    sign_in @author
  end

  test "create adds a comment by the current user, with an unread mention and an email" do
    assert_difference -> { Comment.count } => 1, -> { CommentMention.unread.count } => 1 do
      assert_enqueued_emails 1 do
        post service_comments_url(@service), params: { comment: { body: "<p>#{mention_link(@mentioned)} ver</p>" } }, headers: TURBO_STREAM
      end
    end

    comment = Comment.order(:id).last
    assert_equal @author, comment.user
    assert_equal @mentioned, comment.mentions.sole.user
    assert_includes response.body, %(action="prepend" target="comments_service_#{@service.id}")
    assert_includes response.body, %(action="replace" target="comment_form_service_#{@service.id}")
  end

  test "create is open to users outside the service's guard, so mentioned users can reply" do
    sign_out @author
    sign_in users(:two)

    assert_difference -> { Comment.count } => 1 do
      post service_comments_url(@service), params: { comment: { body: "<p>respuesta</p>" } }, headers: TURBO_STREAM
    end
  end

  test "create doesn't mention the author or users who can't sign in" do
    @mentioned.update!(locked_at: Time.current)

    assert_no_enqueued_emails do
      post service_comments_url(@service), params: { comment: { body: "<p>#{mention_link(@author)} #{mention_link(@mentioned)}</p>" } }, headers: TURBO_STREAM
    end
    assert_equal 0, CommentMention.count
  end

  test "create with a blank comment shows the error and saves nothing" do
    assert_no_difference -> { Comment.count } do
      post service_comments_url(@service), params: { comment: { body: "<p><br></p>" } }, headers: TURBO_STREAM
    end

    assert_response :unprocessable_entity
    assert_includes response.body, Comment.human_attribute_name(:body)
  end

  test "create requires signing in" do
    sign_out @author

    post service_comments_url(@service), params: { comment: { body: "<p>hola</p>" } }

    assert_redirected_to new_user_session_url
  end

  test "destroy lets the author delete their comment and its mentions" do
    comment = @service.comments.create!(user: @author, body: "<p>#{mention_link(@mentioned)}</p>")

    assert_difference -> { Comment.count } => -1, -> { CommentMention.count } => -1 do
      delete service_comment_url(@service, comment), headers: TURBO_STREAM
    end
    assert_includes response.body, %(action="remove" target="#{ActionView::RecordIdentifier.dom_id(comment, :thread)}")
  end

  test "destroy keeps the replies as top-level comments and refreshes the page" do
    comment = @service.comments.create!(user: @author, body: "<p>pregunta</p>")
    reply = @service.comments.create!(user: @mentioned, body: "<p>respuesta</p>", parent: comment)

    delete service_comment_url(@service, comment), headers: TURBO_STREAM

    assert_nil reply.reload.parent
    assert_includes response.body, %(action="refresh")
  end

  test "create links a reply to its parent and adds it first under it" do
    parent = @service.comments.create!(user: @mentioned, body: "<p>pregunta</p>")

    post service_comments_url(@service), params: { comment: { body: "<p>respuesta</p>", parent_id: parent.id } }, headers: TURBO_STREAM

    assert_equal parent, Comment.order(:id).last.parent
    assert_includes response.body, %(action="prepend" target="replies_comment_#{parent.id}")
  end

  test "create lets users reply to their own comment" do
    own = @service.comments.create!(user: @author, body: "<p>mi comentario</p>")

    assert_difference -> { own.replies.count } => 1 do
      post service_comments_url(@service), params: { comment: { body: "<p>agrego algo</p>", parent_id: own.id } }, headers: TURBO_STREAM
    end
    assert_response :success
  end

  test "create doesn't reply to a comment of another record" do
    other = services(:completed_one).comments.create!(user: @mentioned, body: "<p>otro</p>")

    assert_no_difference -> { Comment.count } do
      post service_comments_url(@service), params: { comment: { body: "<p>respuesta</p>", parent_id: other.id } }, headers: TURBO_STREAM
    end
    assert_response :not_found
  end

  test "edit swaps the author's comment for its inline form" do
    comment = @service.comments.create!(user: @author, body: "<p>hola</p>")

    get edit_service_comment_url(@service, comment), headers: TURBO_STREAM

    assert_response :success
    assert_includes response.body, %(action="replace" target="comment_#{comment.id}")
    assert_includes response.body, %(action="/services/#{@service.id}/comments/#{comment.id}")
    assert_includes response.body, I18n.t("comments.edit_form.submit")
  end

  test "edit is denied to other users and once the comment has replies" do
    others = @service.comments.create!(user: @mentioned, body: "<p>ajeno</p>")
    replied = @service.comments.create!(user: @author, body: "<p>pregunta</p>")
    @service.comments.create!(user: @mentioned, body: "<p>respuesta</p>", parent: replied)

    [ others, replied ].each do |comment|
      get edit_service_comment_url(@service, comment), headers: TURBO_STREAM
      assert_redirected_to root_url
    end
  end

  test "update changes the body, marks it edited and shows the comment again" do
    comment = @service.comments.create!(user: @author, body: "<p>hola</p>")

    travel 1.minute do
      patch service_comment_url(@service, comment), params: { comment: { body: "<p>hola de nuevo</p>" } }, headers: TURBO_STREAM
    end

    assert_response :success
    assert_equal "<p>hola de nuevo</p>", comment.reload.body
    assert_includes response.body, %(action="replace" target="comment_#{comment.id}")
    assert_includes response.body, I18n.t("comments.comment.edited")
  end

  test "update notifies only newly mentioned users and drops the mentions removed from the text" do
    kept = users(:unrelated_vocal)
    comment = @service.comments.create!(user: @author, body: "<p>#{mention_link(kept)} #{mention_link(users(:two))}</p>")
    comment.mentions.find_by!(user: kept).read!

    assert_enqueued_emails 1 do
      patch service_comment_url(@service, comment), params: { comment: { body: "<p>#{mention_link(kept)} #{mention_link(@mentioned)}</p>" } }, headers: TURBO_STREAM
    end

    assert_equal [ kept, @mentioned ].map(&:id).sort, comment.mentions.pluck(:user_id).sort
    assert_not comment.mentions.find_by!(user: kept).unread?
    assert comment.mentions.find_by!(user: @mentioned).unread?
  end

  test "update with a blank body shows the form again with the error" do
    comment = @service.comments.create!(user: @author, body: "<p>hola</p>")

    patch service_comment_url(@service, comment), params: { comment: { body: "<p><br></p>" } }, headers: TURBO_STREAM

    assert_response :unprocessable_entity
    assert_equal "<p>hola</p>", comment.reload.body
    assert_includes response.body, Comment.human_attribute_name(:body)
  end

  test "update is denied once the comment has replies" do
    comment = @service.comments.create!(user: @author, body: "<p>pregunta</p>")
    @service.comments.create!(user: @mentioned, body: "<p>respuesta</p>", parent: comment)

    patch service_comment_url(@service, comment), params: { comment: { body: "<p>otra pregunta</p>" } }, headers: TURBO_STREAM

    assert_equal "<p>pregunta</p>", comment.reload.body
  end

  test "show puts the comment back, which cancels an inline edit" do
    comment = @service.comments.create!(user: @author, body: "<p>hola</p>")

    get service_comment_url(@service, comment), headers: TURBO_STREAM

    assert_response :success
    assert_includes response.body, %(action="replace" target="comment_#{comment.id}")
    assert_includes response.body, "hola"
  end

  test "the delete confirmation's button says what it does" do
    comment = @service.comments.create!(user: @author, body: "<p>hola</p>")

    get service_comment_url(@service, comment), headers: TURBO_STREAM

    assert_includes response.body, %(data-turbo-confirm-button="#{I18n.t("comments.comment.destroy_button")}")
  end

  test "replying to your own comment removes its edit button" do
    own = @service.comments.create!(user: @author, body: "<p>mi comentario</p>")

    post service_comments_url(@service), params: { comment: { body: "<p>agrego algo</p>", parent_id: own.id } }, headers: TURBO_STREAM

    assert_includes response.body, %(action="replace" target="comment_#{own.id}")
    assert_not_includes response.body, edit_service_comment_path(@service, own)
  end

  test "destroy is denied to other users but allowed to super admins" do
    comment = @service.comments.create!(user: @mentioned, body: "<p>hola</p>")

    assert_no_difference -> { Comment.count } do
      delete service_comment_url(@service, comment)
    end
    assert_redirected_to root_url

    sign_out @author
    sign_in users(:super_admin)
    assert_difference -> { Comment.count } => -1 do
      delete service_comment_url(@service, comment)
    end
  end

  test "read marks only that comment as read, only for the current user" do
    sign_out @author
    sign_in @mentioned
    clicked = @service.comments.create!(user: @author, body: "<p>#{mention_link(@mentioned)} #{mention_link(users(:unrelated_vocal))}</p>")
    other = @service.comments.create!(user: @author, body: "<p>#{mention_link(@mentioned)}</p>")

    post read_service_comment_url(@service, clicked), headers: TURBO_STREAM

    assert_response :success
    assert_not clicked.mentions.find_by!(user: @mentioned).unread?
    assert clicked.mentions.find_by!(user: users(:unrelated_vocal)).unread?
    assert other.mentions.sole.unread?
  end

  test "read replaces the comment without the unread marks and updates the top nav" do
    sign_out @author
    sign_in @mentioned
    comment = @service.comments.create!(user: @author, body: "<p>#{mention_link(@mentioned)}</p>")

    post read_service_comment_url(@service, comment), headers: TURBO_STREAM

    assert_includes response.body, %(action="replace" target="comment_#{comment.id}")
    assert_includes response.body, %(target="mentions_indicator")
    assert_not_includes response.body, I18n.t("comments.comment.new")
    assert_not_includes response.body, "mark-read"
  end

  test "read of a comment that doesn't mention the user changes nothing" do
    comment = @service.comments.create!(user: @mentioned, body: "<p>#{mention_link(users(:unrelated_vocal))}</p>")

    post read_service_comment_url(@service, comment), headers: TURBO_STREAM

    assert_response :success
    assert comment.mentions.sole.unread?
  end

  test "read only finds comments of that service" do
    comment = services(:completed_one).comments.create!(user: @author, body: "<p>hola</p>")

    post read_service_comment_url(@service, comment), headers: TURBO_STREAM

    assert_response :not_found
  end

  test "read leaves comments unread while an admin impersonates the user" do
    comment = @service.comments.create!(user: @author, body: "<p>#{mention_link(@mentioned)}</p>")
    sign_out @author
    sign_in users(:super_admin)
    post impersonate_user_url(@mentioned)

    post read_service_comment_url(@service, comment), headers: TURBO_STREAM

    assert_response :success
    assert comment.mentions.sole.unread?
    assert_includes response.body, I18n.t("comments.comment.new")
  end

  private

  def mention_link(user)
    %(<a href="/users/#{user.id}">@#{user.full_name}</a>)
  end
end
