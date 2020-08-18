# -*- SkipSchemaAnnotations

# This class is outdated. The latest implementation is a subclass of S3::Tweet.
module S3
  class Profile
    extend S3::Util
    extend S3::ProfileApi

    self.bucket_name = "egotter.#{Rails.env}.profiles"
    self.payload_key = :user_info
  end
end
