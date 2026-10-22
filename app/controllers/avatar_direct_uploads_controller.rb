# Creates the avatar blob on the avatar storage service and returns a presigned URL,
# so the browser uploads the picture straight to S3 instead of through the app.
class AvatarDirectUploadsController < ActiveStorage::DirectUploadsController
  MAX_BYTE_SIZE = 5.megabytes

  before_action :authenticate_user!
  before_action :validate_blob

  private
    def blob_args
      super.merge(service_name: User.reflect_on_attachment(:avatar).options[:service_name].to_s)
    end

    def validate_blob
      args = params.require(:blob)
      unless args[:content_type].to_s.start_with?("image/") && args[:byte_size].to_i.between?(1, MAX_BYTE_SIZE)
        head :unprocessable_content
      end
    end
end
