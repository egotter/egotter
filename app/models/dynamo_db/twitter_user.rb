# -*- SkipSchemaAnnotations
module DynamoDB
  class TwitterUser
    REGION = 'ap-northeast-1'
    TABLE_NAME = "egotter.#{Rails.env}.twitter_users"

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
        obj = dynamo_db_client.get_item(db_key(twitter_user_id)).item
        obj && obj['json'] ? new(parse_json(decompress(obj['json']))) : nil
      end

      def delete_by(twitter_user_id)
        dynamo_db_client.delete_item(db_key(twitter_user_id))
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
            expiration_time: 1.day.since.to_i
        }

        dynamo_db_client.put_item(table_name: TABLE_NAME, item: item)
      end

      def import_from_twitter_user(twitter_user)
        import_from(twitter_user.id, twitter_user.uid, twitter_user.screen_name, twitter_user.send(:profile), twitter_user.friend_uids, twitter_user.follower_uids)
      end

      private

      def db_key(twitter_user_id)
        {table_name: TABLE_NAME, key: {twitter_user_id: twitter_user_id}}
      end

      def dynamo_db_client
        @dynamo_db_client ||= Aws::DynamoDB::Client.new(region: REGION)
      end

      def parse_json(text)
        Oj.load(text, symbol_keys: true)
      rescue Oj::ParseError => e
        raise TypeError.new("#{text} is not a valid JSON source.")
      end

      def compress(text)
        Base64.encode64(Zlib::Deflate.deflate(text))
      end

      def decompress(data)
        Zlib::Inflate.inflate(Base64.decode64(data))
      end
    end

    module Instrumentation
      %i(
        find_by
        delete_by
        import_from
      ).each do |method_name|
        define_method(method_name) do |*args, &blk|
          start = Time.zone.now
          ret_val = method(method_name).super_method.call(*args, &blk)

          time = sprintf("%.1f", Time.zone.now - start)
          Rails.logger.info { "#{self} #{method_name} by #{args[0]}#{' HIT' if ret_val} (#{time}ms)" }

          ret_val
        end
      end
    end
    singleton_class.prepend Instrumentation
  end
end
