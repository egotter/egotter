# -*- SkipSchemaAnnotations

module S3
  class StatusTweet < Tweet
    class << self
      def bucket_name
        "egotter.#{Rails.env}.status-tweets"
      end
    end
  end
end
