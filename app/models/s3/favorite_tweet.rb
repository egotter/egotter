# -*- SkipSchemaAnnotations

require_relative './util'

module S3
  class FavoriteTweet
    BUCKET_NAME = "egotter.#{Rails.env}.favorite-tweets"

    class << self
      def where(uid: nil, screen_name: nil)
        uid = Bot.api_client.user(screen_name)[:id] unless uid # For debugging
        obj = Util.parse_json(get_object(uid))
        tweets = Util.unpack(obj['tweets'])
        tweets.map { |t| ::TwitterDB::Favorite.new(uid: obj['uid'], screen_name: obj['screen_name'], raw_attrs_text: t['raw_attrs_text']) }
      rescue Aws::S3::Errors::NoSuchKey => e
        []
      end

      def import_from!(uid, screen_name, tweets)
        body = encoded_body(uid, screen_name, tweets)
        put_object(uid, body)
      end

      def put_object(key, body)
        raise "#{self} The key is blank" if key.blank?
        benchmark("#{self} Import by #{key} with async") do
          WriteToS3Worker.perform_async(klass: self, bucket: BUCKET_NAME, key: key.to_s, body: body)
        end
      end

      def get_object(key)
        raise "#{self} The key is blank" if key.blank?

        benchmark("#{self} GetObject by #{key}") do
          client.get_object(bucket: BUCKET_NAME, key: key.to_s).body.read
        end
      end

      def encoded_body(uid, screen_name, tweets)
        {
            uid: uid,
            screen_name: screen_name,
            tweets: Util.pack(tweets),
        }.to_json
      end

      def client
        @client ||= Aws::S3::Client.new(region: REGION)
      end

      def benchmark(message, &block)
        ApplicationRecord.benchmark(message, level: :debug, &block)
      end
    end
  end
end
