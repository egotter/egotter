# -*- SkipSchemaAnnotations
module S3
  class Friendship
    extend S3::Util

    self.bucket_name = "egotter.#{Rails.env}.friendships"
    self.uids_key = :friend_uids
  end
end
