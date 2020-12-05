# -*- SkipSchemaAnnotations

module S3
  class ArchiveData
    class << self
      def bucket_name
        "egotter.#{Rails.env}.archive-data"
      end

      def exists?(uid)
        client.object(uid.to_s).exists?
      end

      def presigned_url(uid, filename, filesize)
        object = client.object(uid.to_s)
        meta = {filename: filename, filesize: filesize}
        object.presigned_url(:put, expires_in: 300, acl: 'private', metadata: meta)
      end

      private

      def client
        Aws::S3::Resource.new(region: REGION).bucket(bucket_name)
      end
    end
  end
end
