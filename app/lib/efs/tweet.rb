# -*- SkipSchemaAnnotations

module Efs
  class Tweet

    TWEET_TTL = 1.hour

    def initialize(tweets)
      @tweets = tweets
    end

    def tweets
      @tweets.map do |tweet|
        TwitterDB::Status.new(uid: tweet['uid'], screen_name: tweet['screen_name'], raw_attrs_text: tweet['raw_attrs_text'])
      end
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

      def find_by(uid)
        obj = client.read(uid)
        obj ? new(decompress(obj)['tweets']) : nil
      end

      def import_from!(uid, screen_name, tweets)
        body = compress(uid, screen_name, tweets)
        client.write(uid, body)
      end

      def delete(uid:)
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
