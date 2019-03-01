# -*- SkipSchemaAnnotations
module S3
  class Profile
    extend S3::Util
    extend S3::ProfileApi

    self.bucket_name = "egotter.#{Rails.env}.profiles"
    self.cache_enabled = true
    self.cache_expires_in = 1.week
  end
end
