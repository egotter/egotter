# -*- SkipSchemaAnnotations

module InMemory
  class Tweet
    extend ::InMemory::Util

    def initialize(tweets)
      @tweets = tweets
    end

    def tweets
      @tweets.map do |tweet|
        TwitterDB::Status.new(uid: tweet['uid'], screen_name: tweet['screen_name'], raw_attrs_text: tweet['raw_attrs_text'])
      end
    end

    class << self
      def find_by(uid)
        data = client.read(uid)
        tweets = data ? parse_json(decompress(data), symbol_keys: false) : nil
        tweets ? new(tweets) : nil
      end

      def delete_by(uid)
        client.delete(uid)
      end

      def import_from(uid, tweets)
        client.write(uid, compress(tweets.to_json))
      end

      private

      def client
        ::InMemory::Client.new(self)
      end
    end
  end
end
