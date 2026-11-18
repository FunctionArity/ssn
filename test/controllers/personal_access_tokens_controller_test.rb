require "test_helper"

class PersonalAccessTokensControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:super_admin)
    sign_in @user
  end

  test "lists the user's active tokens, not expired ones nor other users'" do
    mine = PersonalAccessToken.generate_for(@user)
    expired = PersonalAccessToken.generate_for(@user, now: 1.month.ago)
    theirs = PersonalAccessToken.generate_for(users(:two))

    get personal_access_tokens_url

    assert_response :success
    assert_select "##{ActionView::RecordIdentifier.dom_id(mine)}"
    assert_select "##{ActionView::RecordIdentifier.dom_id(expired)}", count: 0
    assert_select "##{ActionView::RecordIdentifier.dom_id(theirs)}", count: 0
    assert_select "form[action='#{personal_access_tokens_path}'] button", text: /#{I18n.t("personal_access_tokens.index.create")}/
    assert_no_match mine.token, response.body
  end

  test "shows an empty list" do
    get personal_access_tokens_url

    assert_select "#personal_access_tokens", text: /#{I18n.t("personal_access_tokens.list.empty")}/
  end

  test "creates a token, shows it once and updates the list with Turbo Streams" do
    assert_difference -> { @user.personal_access_tokens.count }, 1 do
      post personal_access_tokens_url, as: :turbo_stream
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    record = @user.personal_access_tokens.last
    token = css_select("#new_personal_access_token_value").first.text
    assert_equal @user, ApiToken.user_for(token)
    assert_equal record.hint, token.last(6)
    assert_select "turbo-stream[action='update'][target='new_personal_access_token']"
    assert_select "turbo-stream[action='update'][target='personal_access_tokens']" do
      assert_select "template ##{ActionView::RecordIdentifier.dom_id(record)}"
    end
  end

  test "the token it creates calls the API" do
    post personal_access_tokens_url, as: :turbo_stream
    token = css_select("#new_personal_access_token_value").first.text

    get api_v1_me_url, headers: { "Authorization" => "Bearer #{token}" }, as: :json

    assert_response :success
    assert_equal @user.id, response.parsed_body.dig("user", "id")
  end

  test "without Turbo, creating shows the page with the new token" do
    post personal_access_tokens_url

    assert_response :created
    assert_select "#new_personal_access_token_value", text: /\A\S+\z/
  end

  test "revoking a token removes it from the list and the API refuses it" do
    record = PersonalAccessToken.generate_for(@user)

    delete personal_access_token_url(record), as: :turbo_stream

    assert_response :success
    assert_select "turbo-stream[action='update'][target='new_personal_access_token']"
    assert_select "turbo-stream[action='update'][target='personal_access_tokens']" do
      assert_select "template ##{ActionView::RecordIdentifier.dom_id(record)}", count: 0
    end
    assert_not PersonalAccessToken.exists?(record.id)

    get api_v1_me_url, headers: { "Authorization" => "Bearer #{record.token}" }, as: :json
    assert_response :unauthorized
  end

  test "without Turbo, revoking redirects back to the list" do
    record = PersonalAccessToken.generate_for(@user)

    delete personal_access_token_url(record)

    assert_redirected_to personal_access_tokens_path
    assert_equal I18n.t("personal_access_tokens.destroy.revoked"), flash[:notice]
  end

  test "can't revoke another user's token" do
    theirs = PersonalAccessToken.generate_for(users(:two))

    delete personal_access_token_url(theirs), as: :turbo_stream

    assert_response :not_found
    assert PersonalAccessToken.exists?(theirs.id)
  end

  test "not while impersonating someone, even another super admin" do
    other_admin = User.create!(first_name: "Otro", last_name: "Admin", email: "otro@admin.test", password: "password123",
                               user_type: :super_admin)
    post impersonate_user_path(other_admin)

    get personal_access_tokens_url
    assert_redirected_to root_path
    assert_equal I18n.t("personal_access_tokens.impersonating"), flash[:alert]

    assert_no_difference -> { PersonalAccessToken.count } do
      post personal_access_tokens_url, as: :turbo_stream
    end
  end

  test "needs a signed-in user" do
    sign_out @user

    get personal_access_tokens_url

    assert_redirected_to new_user_session_path
  end

  test "only super admins have API tokens" do
    [ users(:one), users(:admin_user) ].each do |user|
      sign_in user

      get personal_access_tokens_url
      assert_redirected_to root_path
      assert_equal I18n.t("pundit.not_authorized"), flash[:alert]

      assert_no_difference -> { PersonalAccessToken.count } do
        post personal_access_tokens_url, as: :turbo_stream
      end
    end
  end

  test "a user no longer super admin can't revoke their old tokens here either" do
    token = PersonalAccessToken.generate_for(@user)
    @user.update!(user_type: :admin)

    delete personal_access_token_url(token), as: :turbo_stream

    assert PersonalAccessToken.exists?(token.id)
  end
end
