# -*- SkipSchemaAnnotations

module S3
  class MentionTweet < Tweet
    class << self
      def bucket_name
        "egotter.#{Rails.env}.mention-tweets"
      end
    end
  end
end
