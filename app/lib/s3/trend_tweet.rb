# -*- SkipSchemaAnnotations

module S3
  class TrendTweet < Tweet
    class << self
      def bucket_name
        "egotter.#{Rails.env}.trend-tweets"
      end
    end
  end
end
