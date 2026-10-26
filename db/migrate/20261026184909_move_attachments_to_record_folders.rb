# Copies existing avatars and guard PDFs to the layout new uploads use:
#
#   avatar/<user id>/<random token>      filename avatar-<user id>.<ext>
#   pdf_file/<guard id>/<random token>   filename guardia_<guard id>.pdf
#
# Each file is copied from where it lives now: the environment's bucket (ssn-dev-/ssn-prd-web-assets),
# or the old shared bucket the app used before. Nothing is deleted: the original stays where it was, as a
# backup, and only the blob row points to the new copy. Files already on the new layout only get
# their filename updated, so the migration can be re-run after a failure.
class MoveAttachmentsToRecordFolders < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  LEGACY_BUCKET = "ssn-web-assets-849322452391-sa-east-1-an".freeze

  ATTACHMENTS = [
    { record_type: "User", name: "avatar", service: :amazon_avatar,
      filename: ->(id, blob) { "avatar-#{id}#{blob.filename.extension_with_delimiter}" } },
    { record_type: "Guard", name: "pdf_file", service: :amazon_pdf_file,
      filename: ->(id, _blob) { "guardia_#{id}.pdf" } }
  ].freeze

  def up
    ATTACHMENTS.each do |config|
      target = ActiveStorage::Blob.services.fetch(config[:service])
      next say("#{config[:service]} is not S3 here, skipping #{config[:record_type]}.#{config[:name]}") unless target.is_a?(ActiveStorage::Service::S3Service)

      ActiveStorage::Attachment.where(record_type: config[:record_type], name: config[:name]).includes(:blob).find_each do |attachment|
        move(attachment, target, config)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "blobs now point to the copies; the originals are still in their old location"
  end

  private
    def move(attachment, target, config)
      blob = attachment.blob
      filename = config[:filename].call(attachment.record_id, blob)
      if blob.key.start_with?("#{attachment.record_id}/") && blob.service_name == config[:service].to_s
        return blob.update_columns(filename: filename)
      end

      source = blob.service
      old_path = object_for(source, blob.key).key
      source_bucket = source.bucket.object(old_path).exists? ? source.bucket.name : LEGACY_BUCKET

      unless Aws::S3::Object.new(source_bucket, old_path, client: source.client.client).exists?
        return say("missing in S3, skipped: blob #{blob.id} (#{config[:record_type]} #{attachment.record_id}) at #{old_path}")
      end

      new_key = "#{attachment.record_id}/#{ActiveStorage::Blob.generate_unique_secure_token}"
      new_object = object_for(target, new_key)
      new_object.copy_from(copy_source: "#{source_bucket}/#{old_path}")

      blob.update_columns(key: new_key, service_name: config[:service].to_s, filename: filename)

      say("#{config[:record_type]} #{attachment.record_id}: s3://#{source_bucket}/#{old_path} -> s3://#{target.bucket.name}/#{new_object.key}")
    end

    # PrefixedS3Service adds its folder in object_for, which S3Service keeps private.
    def object_for(service, key)
      service.send(:object_for, key)
    end
end
