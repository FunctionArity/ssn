require "active_storage/service/s3_service"

class ActiveStorage::Service::PrefixedS3Service < ActiveStorage::Service::S3Service
  def initialize(prefix:, **options)
    @key_prefix = prefix
    super(**options)
  end

  private

  def object_for(key)
    bucket.object("#{@key_prefix}/#{key}")
  end

  def delete_prefixed(prefix)
    instrument :delete_prefixed, prefix: prefix do
      bucket.objects(prefix: "#{@key_prefix}/#{prefix}").batch_delete!
    end
  end
end
