# -*- SkipSchemaAnnotations
module S3
  class Profile
    extend S3::Util
    extend S3::ProfileApi

    self.bucket_name = "egotter.#{Rails.env}.profiles"
    self.payload_key = :user_info
  end
end
