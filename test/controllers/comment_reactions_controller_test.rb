require "test_helper"

class CommentReactionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  TURBO_STREAM = { "Accept" => "text/vnd.turbo-stream.html" }.freeze

  setup do
    @service = services(:one)
    @comment = @service.comments.create!(user: users(:one), body: "<p>hola</p>")
    @user = users(:vocal_guardian)
    sign_in @user
  end

  test "create adds the current user's reaction and shows the comment's reactions again" do
    assert_difference -> { @comment.reactions.count } => 1 do
      post service_comment_reactions_url(@service, @comment), params: { emoji: "👍" }, headers: TURBO_STREAM
    end

    assert_response :success
    assert_equal [ @user, "👍" ], @comment.reactions.sole.then { |reaction| [ reaction.user, reaction.emoji ] }
    assert_includes response.body, %(action="replace" target="reactions_comment_#{@comment.id}")
    assert_select "button[aria-pressed=true][title=?]", @user.full_name, text: /👍\s*1/
  end

  test "reacting again with the same emoji takes the reaction back" do
    @comment.reactions.create!(user: @user, emoji: "❤️")

    assert_difference -> { @comment.reactions.count } => -1 do
      post service_comment_reactions_url(@service, @comment), params: { emoji: "❤️" }, headers: TURBO_STREAM
    end
    assert_response :success
  end

  test "each user and emoji count separately, and other users' reactions stay" do
    @comment.reactions.create!(user: users(:one), emoji: "👍")

    post service_comment_reactions_url(@service, @comment), params: { emoji: "👍" }, headers: TURBO_STREAM
    post service_comment_reactions_url(@service, @comment), params: { emoji: "😂" }, headers: TURBO_STREAM

    assert_equal({ "👍" => 2, "😂" => 1 }, @comment.reactions.group(:emoji).count)
    assert_select "button[aria-pressed=true]", text: /👍\s*2/
  end

  test "a double click whose other click already saved the reaction doesn't fail" do
    # The other click saves it between this one's uniqueness check and its insert, so the database refuses the insert.
    uniqueness = CommentReaction.validators_on(:emoji).grep(ActiveRecord::Validations::UniquenessValidator).sole
    duplicate_insert = ->(*) { raise ActiveRecord::RecordNotUnique, "duplicate key value violates unique constraint" }

    uniqueness.stub(:validate_each, duplicate_insert) do
      post service_comment_reactions_url(@service, @comment), params: { emoji: "👍" }, headers: TURBO_STREAM
    end

    assert_response :success
    assert_includes response.body, %(action="replace" target="reactions_comment_#{@comment.id}")
  end

  test "an emoji outside the list is rejected" do
    assert_no_difference -> { CommentReaction.count } do
      post service_comment_reactions_url(@service, @comment), params: { emoji: "💩" }, headers: TURBO_STREAM
    end
    assert_response :unprocessable_entity
  end

  test "without turbo it goes back to the comment" do
    post service_comment_reactions_url(@service, @comment), params: { emoji: "🙏" }

    assert_redirected_to service_path(@service, anchor: "comment_#{@comment.id}")
  end

  test "only comments of that service are found" do
    post service_comment_reactions_url(services(:completed_one), @comment), params: { emoji: "👍" }, headers: TURBO_STREAM

    assert_response :not_found
  end

  test "signed out users can't react" do
    sign_out @user

    assert_no_difference -> { CommentReaction.count } do
      post service_comment_reactions_url(@service, @comment), params: { emoji: "👍" }, headers: TURBO_STREAM
    end
    assert_redirected_to new_user_session_url
  end

  test "the service page shows each comment's reactions, with who reacted, and the picker" do
    @comment.reactions.create!(user: users(:one), emoji: "😮")

    get service_url(@service)

    assert_select "#reactions_comment_#{@comment.id}" do
      assert_select "button[aria-pressed=false][title=?]", users(:one).full_name, text: /😮\s*1/
      assert_select "button[aria-expanded=false][aria-controls=?]", "reaction_picker_comment_#{@comment.id}"
      assert_select "#reaction_picker_comment_#{@comment.id}[hidden] button", count: CommentReaction::EMOJIS.size
    end
  end

  test "deleting a comment or a user deletes their reactions" do
    reactor = User.create!(first_name: "Ana", last_name: "Zapata", email: "ana@example.test", phone: "2222222222", password: SecureRandom.hex)
    @comment.reactions.create!(user: reactor, emoji: "👍")
    other = @service.comments.create!(user: users(:one), body: "<p>otro</p>")
    other.reactions.create!(user: reactor, emoji: "👍")

    assert_difference -> { CommentReaction.count } => -1 do
      @comment.destroy!
    end
    assert_difference -> { CommentReaction.count } => -1 do
      reactor.destroy!
    end
  end
end
