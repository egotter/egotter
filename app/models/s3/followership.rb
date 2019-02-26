# -*- SkipSchemaAnnotations
module S3
  class Followership
    extend S3::Util

    self.bucket_name = "egotter.#{Rails.env}.followerships"
    self.uids_key = :follower_uids
  end
end
