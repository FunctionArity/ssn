require "active_storage/service/s3_service"

class ActiveStorage::Service::PrefixedS3Service < ActiveStorage::Service::S3Service
  def initialize(prefix:, **options)
    @key_prefix = prefix
    super(**options)
  end

  # Public, like the S3Service method it overrides: purging a blob calls it to delete its variants.
  def delete_prefixed(prefix)
    instrument :delete_prefixed, prefix: prefix do
      bucket.objects(prefix: "#{@key_prefix}/#{prefix}").batch_delete!
    end
  end

  private

  def object_for(key)
    bucket.object("#{@key_prefix}/#{key}")
  end
end
