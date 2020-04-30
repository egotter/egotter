# -*- SkipSchemaAnnotations

require_relative '../dynamo_db'

module DynamoDB
  class TwitterUser
    extend ::DynamoDB::Util

    attr_reader :uid, :screen_name, :profile, :friend_uids, :follower_uids

    def initialize(attrs)
      @uid = attrs[:uid]
      @screen_name = attrs[:screen_name]
      @profile = attrs[:profile]
      @friend_uids = attrs[:friend_uids]
      @follower_uids = attrs[:follower_uids]
    end

    class << self
      def table_name
        "egotter.#{Rails.env}.twitter_users"
      end

      def partition_key
        'twitter_user_id'
      end

      def find_by(twitter_user_id)
        item = client.read(twitter_user_id).item
        item && item['json'] ? new(parse_json(decompress(item['json']))) : nil
      rescue => e
        Rails.logger.warn "#{self}##{__method__} failed #{e.inspect}"
        nil
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

        item = {
            twitter_user_id: twitter_user_id,
            json: compress(payload.to_json),
            expiration_time: TABLE_TTL.since.to_i
        }

        client.write(twitter_user_id, item)
      end

      def import_from_twitter_user(twitter_user)
        import_from(twitter_user.id, twitter_user.uid, twitter_user.screen_name, twitter_user.send(:profile), twitter_user.friend_uids, twitter_user.follower_uids)
      end

      private

      def client
        @client ||= ::DynamoDB::Client.new(self, table_name, partition_key)
      end
    end
  end
end
