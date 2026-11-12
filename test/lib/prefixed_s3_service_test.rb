require "test_helper"
require "active_storage/service/prefixed_s3_service"

class PrefixedS3ServiceTest < ActiveSupport::TestCase
  setup do
    @service = ActiveStorage::Service::PrefixedS3Service.new(prefix: "avatar", bucket: "bucket", region: "us-east-1", stub_responses: true)
  end

  test "deletes a blob's variants inside its prefix, as purging a blob calls it from outside" do
    client = @service.client.client
    client.stub_responses(:list_objects_v2, contents: [ { key: "avatar/variants/abc/1" } ])

    @service.delete_prefixed("variants/abc/")

    assert_equal "avatar/variants/abc/", client.api_requests.find { |r| r[:operation_name] == :list_objects_v2 }[:params][:prefix]
    assert client.api_requests.any? { |r| r[:operation_name] == :delete_objects }
  end

  test "keeps every blob inside its prefix" do
    client = @service.client.client

    @service.exist?("abc123")

    assert_equal "avatar/abc123", client.api_requests.find { |r| r[:operation_name] == :head_object }[:params][:key]
  end
end
