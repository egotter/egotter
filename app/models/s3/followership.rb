# -*- SkipSchemaAnnotations

# This class is outdated. The latest implementation is a subclass of S3::Tweet.
module S3
  class Followership
    extend S3::Util
    extend S3::Api

    self.bucket_name = "egotter.#{Rails.env}.followerships"
    self.payload_key = :follower_uids
  end
end
