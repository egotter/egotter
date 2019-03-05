# -*- SkipSchemaAnnotations
module TwitterDB
  module S3
    class Followership
      extend ::S3::Util
      extend TwitterDB::S3::Api

      self.bucket_name = "egotter.#{Rails.env}.twitter-db.followerships"
      self.payload_key = :follower_uids
      self.cache_enabled = true
    end
  end
end
