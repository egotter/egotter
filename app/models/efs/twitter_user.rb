# -*- SkipSchemaAnnotations
module Efs
  class TwitterUser
    attr_reader :uid, :screen_name, :profile, :friend_uids, :follower_uids

    def initialize(attrs)
      @uid = attrs[:uid]
      @screen_name = attrs[:screen_name]
      @profile = attrs[:profile]
      @friend_uids = attrs[:friend_uids]
      @follower_uids = attrs[:follower_uids]
    end

    class << self
      def find_by(twitter_user_id)
        start = Time.zone.now

        obj = cache_client.read(cache_key(twitter_user_id))
        result = obj ? new(parse_json(decompress(obj))) : nil

        time = sprintf("%.1f", Time.zone.now - start)
        Rails.logger.debug { "#{self} Fetch by #{twitter_user_id}#{' HIT' if result} (#{time}ms)" }

        result
      end

      def delete_by(twitter_user_id)
        cache_client.delete(cache_key(twitter_user_id))
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

      def import_from_s3!(twitter_user, skip_if_found: false, threads: true)
        return if skip_if_found && find_by(twitter_user.id)

        ApplicationRecord.benchmark("#{self} Import from s3 by #{twitter_user.id}", level: :debug) do
          profile, friend_uids, follower_uids = threads ? work_in_threads(twitter_user) : work_direct(twitter_user)
          import_from!(twitter_user.id, twitter_user.uid, twitter_user.screen_name, profile, friend_uids, follower_uids)
        end
      end

      def work_direct(twitter_user)
        [
            S3::Profile.find_by(twitter_user_id: twitter_user.id)[:user_info],
            S3::Friendship.find_by(twitter_user_id: twitter_user.id)&.friend_uids,
            S3::Followership.find_by(twitter_user_id: twitter_user.id)&.follower_uids
        ]
      end

      def work_in_threads(twitter_user)
        results = Parallel.map([S3::Profile, S3::Friendship, S3::Followership], in_threads: 3) do |klass|
          klass.find_by(twitter_user_id: twitter_user.id)
        end
        [results[0][:user_info], results[1]&.friend_uids, results[2]&.follower_uids]
      end

      def cache_key(twitter_user_id)
        "efs_twitter_user_cache:#{twitter_user_id}"
      end

      # TODO Use Efs::Client
      # TODO Remove redundant benchmark

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
      rescue Oj::ParseError => e
        raise TypeError.new("#{text} is not a valid JSON source.")
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
