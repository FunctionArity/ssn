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
    assert_includes response.body, %(action="remove" target="#{ActionView::RecordIdentifier.dom_id(comment)}")
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
