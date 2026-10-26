require "test_helper"

class AvatarDirectUploadsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @blob_params = {
      filename: "avatar.jpg",
      byte_size: 1024,
      checksum: Digest::MD5.base64digest("x" * 1024),
      content_type: "image/jpeg"
    }
  end

  test "creates the blob on the avatar service and returns direct upload details" do
    sign_in users(:one)

    assert_difference "ActiveStorage::Blob.count", 1 do
      post user_avatar_direct_uploads_url(users(:one)), params: { blob: @blob_params }, as: :json
    end

    assert_response :success
    json = response.parsed_body
    blob = ActiveStorage::Blob.find_signed!(json["signed_id"])
    assert_equal "amazon_avatar", blob.service_name
    assert_match %r{\A#{users(:one).id}/[a-z0-9]{28}\z}, blob.key
    assert json.dig("direct_upload", "url").present?
  end

  test "ignores a key sent by the browser" do
    sign_in users(:one)

    post user_avatar_direct_uploads_url(users(:one)), params: { blob: @blob_params.merge(key: "someone-else/avatar") }, as: :json

    assert_match %r{\A#{users(:one).id}/}, ActiveStorage::Blob.find_signed!(response.parsed_body["signed_id"]).key
  end

  test "regular user cannot upload an avatar for another user" do
    sign_in users(:one)

    assert_no_difference "ActiveStorage::Blob.count" do
      post user_avatar_direct_uploads_url(users(:two)), params: { blob: @blob_params }, as: :json
    end

    assert_response :forbidden
  end

  test "admin uploads another user's avatar under that user's id" do
    sign_in users(:admin_user)

    post user_avatar_direct_uploads_url(users(:two)), params: { blob: @blob_params }, as: :json

    assert_response :success
    assert_match %r{\A#{users(:two).id}/}, ActiveStorage::Blob.find_signed!(response.parsed_body["signed_id"]).key
  end

  test "rejects non image uploads" do
    sign_in users(:one)

    assert_no_difference "ActiveStorage::Blob.count" do
      post user_avatar_direct_uploads_url(users(:one)), params: { blob: @blob_params.merge(content_type: "application/pdf") }, as: :json
    end

    assert_response :unprocessable_content
  end

  test "rejects uploads larger than the limit" do
    sign_in users(:one)

    assert_no_difference "ActiveStorage::Blob.count" do
      post user_avatar_direct_uploads_url(users(:one)), params: { blob: @blob_params.merge(byte_size: 6.megabytes) }, as: :json
    end

    assert_response :unprocessable_content
  end

  test "requires authentication" do
    assert_no_difference "ActiveStorage::Blob.count" do
      post user_avatar_direct_uploads_url(users(:one)), params: { blob: @blob_params }, as: :json
    end

    assert_response :unauthorized
  end

  test "user update attaches the uploaded avatar by signed id" do
    user = users(:one)
    sign_in user
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("img"), filename: "avatar.jpg",
                                                  content_type: "image/jpeg", service_name: "amazon_avatar")

    patch user_url(user), params: { user: { first_name: user.first_name, avatar: blob.signed_id } }

    assert_equal blob, user.reload.avatar.blob
  end
end
