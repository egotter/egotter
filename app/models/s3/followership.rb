# -*- SkipSchemaAnnotations
module S3
  class Followership
    extend S3::Util
    extend S3::Api

    self.bucket_name = "egotter.#{Rails.env}.followerships"
    self.payload_key = :follower_uids
  end
end
