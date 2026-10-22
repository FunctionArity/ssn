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
      post avatar_direct_uploads_url, params: { blob: @blob_params }, as: :json
    end

    assert_response :success
    json = response.parsed_body
    assert_equal "amazon_avatar", ActiveStorage::Blob.find_signed!(json["signed_id"]).service_name
    assert json.dig("direct_upload", "url").present?
  end

  test "rejects non image uploads" do
    sign_in users(:one)

    assert_no_difference "ActiveStorage::Blob.count" do
      post avatar_direct_uploads_url, params: { blob: @blob_params.merge(content_type: "application/pdf") }, as: :json
    end

    assert_response :unprocessable_content
  end

  test "rejects uploads larger than the limit" do
    sign_in users(:one)

    assert_no_difference "ActiveStorage::Blob.count" do
      post avatar_direct_uploads_url, params: { blob: @blob_params.merge(byte_size: 6.megabytes) }, as: :json
    end

    assert_response :unprocessable_content
  end

  test "requires authentication" do
    assert_no_difference "ActiveStorage::Blob.count" do
      post avatar_direct_uploads_url, params: { blob: @blob_params }, as: :json
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
