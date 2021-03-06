# -*- SkipSchemaAnnotations

module S3
  class ArchiveData

    FILENAME_REGEXP = /\Atwitter-20\d{2}-\d{2}-\d{2}-[a-z0-9-]+.zip\z/

    class << self
      # TODO Remove later
      def bucket_name
        delete_tweets_bucket_name
      end

      def delete_tweets_bucket_name
        "egotter.#{Rails.env}.archive-data"
      end

      def delete_favorites_bucket_name
        "egotter.#{Rails.env}.delete-favorites-archive-data"
      end

      def delete_tweets_identity_pool_id
        ENV['DELETE_TWEETS_IDENTITY_POOL_ID']
      end

      def delete_favorites_identity_pool_id
        ENV['DELETE_FAVORITES_IDENTITY_POOL_ID']
      end

      # TODO Remove later
      def exists?(uid)
        client.object(uid.to_s).exists?
      end

      def presigned_url(key, raw_filename, raw_filesize)
        object = client.object(key)
        meta = {filename: raw_filename, filesize: raw_filesize}
        object.presigned_url(:put, expires_in: 300, acl: 'private', metadata: meta)
      end

      private

      def client
        # TODO Fix invalid bucket name
        Aws::S3::Resource.new(region: REGION).bucket(bucket_name)
      end
    end
  end
end
