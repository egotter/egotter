# -*- SkipSchemaAnnotations
module Efs
  class TwitterUser
    class << self
      def find_by(twitter_user_id)
        ApplicationRecord.benchmark("#{self} Fetch by #{twitter_user_id}", level: :debug) do
          obj = cache_client.read(cache_key(twitter_user_id))
          obj ? parse_json(decompress(obj)) : obj
        end
      end

      def import_from!(twitter_user_id, uid, screen_name, profile, friend_uids, follower_uids)
        profile = parse_json(profile) if profile.class == String
        json = {
            twitter_user_id: twitter_user_id,
            uid: uid,
            screen_name: screen_name,
            profile: profile,
            friend_uids: friend_uids,
            follower_uids: follower_uids
        }.to_json

        cache_client.write(cache_key(twitter_user_id), compress(json))
      end

      def import_from_s3!(twitter_user_id, skip_if_found: false)
        return if skip_if_found && find_by(twitter_user_id)

        ApplicationRecord.benchmark("#{self} Import from s3 by #{twitter_user_id}", level: :debug) do
          twitter_user = ::TwitterUser.find(twitter_user_id)
          profile = parse_json(S3::Profile.find_by(twitter_user_id: twitter_user_id)[:user_info])
          friend_uids = S3::Friendship.find_by(twitter_user_id: twitter_user_id)[:friend_uids]
          follower_uids = S3::Followership.find_by(twitter_user_id: twitter_user_id)[:follower_uids]
          import_from!(twitter_user_id, twitter_user.uid, twitter_user.screen_name, profile, friend_uids, follower_uids)
        end
      end

      def cache_key(twitter_user_id)
        "efs_twitter_user_cache:#{twitter_user_id}"
      end

      def cache_client
        if instance_variable_defined?(:@cache_client)
          @cache_client
        else
          dir = Rails.root.join(CacheDirectory.find_by(name: 'efs_twitter_user')&.dir || 'tmp/efs_cache')
          FileUtils.mkdir_p(dir) unless File.exists?(dir)
          options = {expires_in: 1.month, race_condition_ttl: 5.minutes}
          @cache_client = ActiveSupport::Cache::FileStore.new(dir, options)
        end
      end

      def parse_json(text)
        Oj.load(text, symbol_keys: true)
      end

      def compress(text)
        Zlib::Deflate.deflate(text)
      end

      def decompress(data)
        Zlib::Inflate.inflate(data)
      end
    end
  end
end
