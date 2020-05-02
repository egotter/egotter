# -*- SkipSchemaAnnotations

module DynamoDB
  class Tweet
    extend ::DynamoDB::Util

    attr_reader :raw_attrs_text

    def initialize(tweet)
      @raw_attrs_text = tweet[:raw_attrs_text]
    end

    class << self
      def table_name
        raise NotImplementedError
      end

      def partition_key
        'uid'
      end

      def array_from(tweets)
        tweets.map { |t| new(t) }
      end

      def find_by(uid)
        item = client.read(uid).item
        tweets = item && item['json'] ? parse_json(decompress(item['json'])) : nil
        tweets ? array_from(tweets[:tweets]) : []
      rescue => e
        Rails.logger.warn "#{self}##{__method__} failed #{e.inspect}"
        []
      end

      def delete_by(uid)
        client.delete(uid)
      end

      def import_from(uid, tweets)
        payload = {tweets: tweets}
        item = {
            uid: uid,
            json: compress(payload.to_json),
            expiration_time: TABLE_TTL.since.to_i
        }

        client.write(uid, item)
      end

      private

      def client
        @client ||= ::DynamoDB::Client.new(self, table_name, partition_key)
      end
    end
  end
end
