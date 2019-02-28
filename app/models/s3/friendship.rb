# -*- SkipSchemaAnnotations
module S3
  class Friendship
    extend S3::Util
    extend S3::Api

    self.bucket_name = "egotter.#{Rails.env}.friendships"
    self.uids_key = :friend_uids
    self.cache_enabled = true
  end
end
