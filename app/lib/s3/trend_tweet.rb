# -*- SkipSchemaAnnotations

module S3
  class TrendTweet < Tweet
    class << self
      def bucket_name
        "egotter.#{Rails.env}.trend-tweets"
      end
    end

    def tweets
      @tweets.map do |tweet|
        TrendSearcher::Tweet.from_hash(tweet['raw_attrs_text'])
      end
    end
  end
end
