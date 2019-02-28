# -*- SkipSchemaAnnotations
module TwitterDB
  module S3
    class Friendship
      extend ::S3::Util
      extend TwitterDB::S3::Api

      self.bucket_name = "egotter.#{Rails.env}.twitter-db.friendships"
      self.uids_key = :friend_uids
    end
  end
end
