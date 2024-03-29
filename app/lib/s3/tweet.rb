# -*- SkipSchemaAnnotations

module S3
  class Tweet

    def initialize(tweets, time = nil)
      @tweets = tweets
      @time = time
    end

    def tweets
      @tweets.map do |tweet|
        TwitterDB::Status.new(uid: tweet['uid'], screen_name: tweet['screen_name'], raw_attrs_text: tweet['raw_attrs_text'])
      end
    end

    def tweets_bytesize
      @tweets.map { |tweet| tweet.inspect.size }.sum
    end

    # For debugging
    def created_at
      Time.zone.parse(@time)
    end

    class << self
      def bucket_name
        'not-specified'
      end

      # TODO Implement as a general class
      # uid -> resource_id
      # screen_name -> resource_name
      # tweets -> collection

      def find_by(uid)
        if (obj = client.read(uid))
          obj = decode(obj)
          new(obj['tweets'], obj['time'])
        end
      rescue Aws::S3::Errors::NoSuchKey => e
        nil
      end

      def import_from!(uid, screen_name, tweets, async: true)
        body = encode(uid, screen_name, tweets)
        client.write(uid, body, async: async)
      end

      def delete(uid:)
        client.delete(uid)
      end

      def encode(uid, screen_name, tweets)
        {
            uid: uid,
            screen_name: screen_name,
            tweets: ::S3::Util.pack(tweets),
            time: Time.zone.now.to_s,
        }.to_json
      end

      def decode(obj)
        obj = ::S3::Util.parse_json(obj)
        obj['tweets'] = ::S3::Util.unpack(obj['tweets'])
        obj
      end

      def client
        @client ||= ::S3::Client.new(bucket_name, self)
      end
    end
  end
end
