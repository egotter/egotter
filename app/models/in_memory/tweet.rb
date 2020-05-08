# -*- SkipSchemaAnnotations

module InMemory
  class Tweet
    extend ::InMemory::Util

    attr_reader :raw_attrs_text

    def initialize(tweet)
      @raw_attrs_text = tweet[:raw_attrs_text]
    end

    class << self
      def hostname
        ENV['IN_MEMORY_REDIS_HOST']
      end

      def array_from(tweets)
        tweets.map { |t| new(t) }
      end

      def find_by(uid)
        data = client.read(uid)
        tweets = data ? parse_json(decompress(data)) : nil
        tweets ? array_from(tweets) : []
      rescue => e
        Rails.logger.warn "#{self}##{__method__} failed #{e.inspect}"
        []
      end

      def delete_by(uid)
        client.delete(uid)
      end

      def import_from(uid, tweets)
        client.write(uid, compress(tweets.to_json))
      end

      def used_memory
        client.instance_variable_get(:@redis).info['used_memory_rss_human']
      end

      private

      def client
        @client ||= ::InMemory::Client.new(self, hostname)
      end
    end
  end
end
