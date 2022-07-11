require 'singleton'

module Efs
  class TwitterUser
    extend ::Efs::Util

    attr_reader :uid, :screen_name, :profile, :friend_uids, :follower_uids

    def initialize(attrs)
      @uid = attrs[:uid]
      @screen_name = attrs[:screen_name]
      @profile = attrs[:profile]
      @friend_uids = attrs[:friend_uids]
      @follower_uids = attrs[:follower_uids]
    end

    class TimeoutError < Timeout::Error
    end

    class << self
      def find_by(twitter_user_id)
        Timeout.timeout(3.seconds) do
          obj = client.read(twitter_user_id)
          obj ? new(unpack(obj)) : nil
        end
      rescue Timeout::Error => e
        raise TimeoutError.new(e.message)
      end

      def delete_by(twitter_user_id)
        client.delete(twitter_user_id)
      end

      def exists?(twitter_user_id)
        client.exist?(twitter_user_id)
      end

      def import_from!(twitter_user_id, uid, screen_name, profile, friend_uids, follower_uids)
        profile = parse_json(profile) if profile.class == String
        data = pack(
            twitter_user_id: twitter_user_id,
            uid: uid,
            screen_name: screen_name,
            profile: profile,
            friend_uids: friend_uids,
            follower_uids: follower_uids
        )
        client.write(twitter_user_id, data)
      end

      def client
        Client.instance
      end

      def pack(obj)
        compress(obj.to_json)
      end

      def unpack(obj)
        obj ? parse_json(decompress(obj)) : nil
      end

      class Client
        include Singleton

        def initialize
          dir = Rails.root.join(CacheDirectory.find_by(name: 'efs_twitter_user')&.dir || 'tmp/efs_cache')
          FileUtils.mkdir_p(dir) unless File.exists?(dir)
          options = {expires_in: 1.month, race_condition_ttl: 5.minutes}
          @efs = ActiveSupport::Cache::FileStore.new(dir, **options)
        end

        def read(id)
          @efs.read(key(id))
        end

        def write(id, data)
          @efs.write(key(id), data)
        end

        def exist?(id)
          @efs.exist?(key(id))
        end

        def delete(id)
          @efs.delete(key(id))
        end

        private

        def key(id)
          "efs_twitter_user_cache:#{id}"
        end
      end
    end
  end
end
