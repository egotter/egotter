# -*- SkipSchemaAnnotations
module TwitterDB
  module S3
    class Profile
      extend ::S3::Util
      extend TwitterDB::S3::ProfileApi

      self.bucket_name = "egotter.#{Rails.env}.twitter-db.profiles"
    end
  end
end
