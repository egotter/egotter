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
        TweetWrapper.new(uid: tweet['uid'], screen_name: tweet['screen_name'], properties: JSON.parse(tweet['raw_attrs_text']))
      end
    end

    class TweetWrapper
      attr_reader :uid, :screen_name

      def initialize(uid:, screen_name:, properties: {})
        @uid = uid
        @screen_name = screen_name
        @properties = properties
      end

      def user
        if instance_variable_defined?(:@user)
          @user
        else
          @user = TwitterDB::User.find_by(uid: @uid)
        end
      end

      def text
        @properties['text']
      end

      def tweet_id
        @properties['id']
      end

      def tweeted_at
        Time.zone.parse(@properties['created_at'])
      end

      def retweeted_status
        if (tweet = @properties['retweeted_status'])
          properties = {'id' => tweet['id'], 'text' => tweet['text'], 'created_at' => tweet['created_at']}
          TweetWrapper.new(uid: tweet['uid'], screen_name: tweet['screen_name'], properties: properties)
        else
          nil
        end
      end
    end
  end
end
