# -*- SkipSchemaAnnotations

module Efs
  class Tweet
    class << self
      def where(uid: nil, screen_name: nil)
        uid = Bot.api_client.user(screen_name)[:id] unless uid # For debugging
        if (obj = cache.get_object(uid))
          decode(obj)['tweets']
        else
          []
        end
      end

      def import_from!(uid, screen_name, tweets)
        body = encode(uid, screen_name, tweets)
        cache.put_object(uid, body)
      end

      def delete(uid: nil, screen_name: nil)
        uid = Bot.api_client.user(screen_name)[:id] unless uid # For debugging
        cache.delete_object(uid)
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

      def cache
        @cache ||= ::Efs::Cache.new(key_prefix, self)
      end
    end
  end
end
