# -*- SkipSchemaAnnotations
module S3
  class Followership
    extend S3::Util
    extend S3::Api

    self.bucket_name = "egotter.#{Rails.env}.followerships"
    self.uids_key = :follower_uids
    self.cache_enabled = true
    self.cache_expires_in = 1.week
  end
end
