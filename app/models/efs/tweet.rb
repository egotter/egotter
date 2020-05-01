# -*- SkipSchemaAnnotations

module Efs
  class Tweet
    attr_reader :raw_attrs_text

    TWEET_TTL = 1.hour

    def initialize(tweet)
      @raw_attrs_text = tweet['raw_attrs_text']
    end

    class << self
      def key_prefix
        'not-specified'
      end

      def mounted_dir
        'not-specified'
      end

      def cache_alive?(time)
        time > TWEET_TTL.ago
      end

      def array_from(tweets)
        tweets.map { |t| new(t) }
      end

      def where(uid: nil, screen_name: nil)
        uid = Bot.api_client.user(screen_name)[:id] unless uid # For debugging
        obj = client.read(uid)
        obj ? array_from(decompress(obj)['tweets']) : []
      end

      def import_from!(uid, screen_name, tweets)
        body = compress(uid, screen_name, tweets)
        client.write(uid, body)
      end

      def delete(uid: nil, screen_name: nil)
        uid = Bot.api_client.user(screen_name)[:id] unless uid # For debugging
        client.delete(uid)
      end

      def compress(uid, screen_name, tweets)
        {
            uid: uid,
            screen_name: screen_name,
            tweets: ::S3::Util.pack(tweets),
            time: Time.zone.now.to_s,
        }.to_json
      end

      def decompress(obj)
        obj = ::S3::Util.parse_json(obj)
        obj['tweets'] = ::S3::Util.unpack(obj['tweets'])
        obj
      end

      def client
        @client ||= ::Efs::Client.new(key_prefix, self, mounted_dir)
      end
    end
  end
end
