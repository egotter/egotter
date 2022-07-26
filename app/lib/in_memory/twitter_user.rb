module InMemory
  class TwitterUser
    extend ::InMemory::Util

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
        data = client.read(twitter_user_id)
        data ? new(parse_json(decompress(data))) : nil
      end

      def delete_by(twitter_user_id)
        client.delete(twitter_user_id)
      end

      def import_from(twitter_user_id, uid, screen_name, profile, friend_uids, follower_uids)
        profile = parse_json(profile) if profile.class == String
        payload = {
            uid: uid,
            screen_name: screen_name,
            profile: profile,
            friend_uids: friend_uids,
            follower_uids: follower_uids
        }
        client.write(twitter_user_id, compress(payload.to_json))
      end
    end
  end
end
