# -*- SkipSchemaAnnotations

# This class is outdated. The latest implementation is a subclass of S3::Tweet.
module S3
  class Friendship
    extend S3::Util
    extend S3::Api

    self.bucket_name = "egotter.#{Rails.env}.friendships"
    self.payload_key = :friend_uids
  end
end
