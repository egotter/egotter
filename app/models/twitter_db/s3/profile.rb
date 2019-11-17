# -*- SkipSchemaAnnotations
module TwitterDB
  module S3
    class Profile
      extend ::S3::Util
      extend TwitterDB::S3::ProfileApi

      self.bucket_name = "egotter.#{Rails.env}.twitter-db.profiles"
      self.payload_key = :user_info
    end
  end
end
