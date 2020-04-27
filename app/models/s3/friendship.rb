# -*- SkipSchemaAnnotations

# This class is outdated. The latest implementation is a subclass of S3::Tweet.
module S3
  class Friendship
    extend S3::Util
    extend S3::Api

    self.bucket_name = "egotter.#{Rails.env}.friendships"
    self.payload_key = :friend_uids

    attr_reader :friend_uids

    def initialize(attrs)
      @friend_uids = attrs[:friend_uids]
    end
  end
end
