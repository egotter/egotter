# -*- SkipSchemaAnnotations
module DynamoDB
  class Friendship
    REGION = 'ap-northeast-1'
    TABLE_NAME = "egotter.#{Rails.env}.friendships"

    class << self
      def client
        @@client ||= Aws::DynamoDB::Client.new(region: REGION)
      end

      def find_by(twitter_user_id:)
        item = client.get_item(table_name: TABLE_NAME, key: {twitter_user_id: twitter_user_id}).item
        {
            twitter_user_id: item['twitter_user_id'],
            uid: item['uid'],
            screen_name: item['screen_name'],
            friend_uids: item['friend_uids']
        }
      end

      def import_by!(twitter_user:)
        client.put_item(
            table_name: TABLE_NAME,
            item: {
                twitter_user_id: twitter_user.id,
                uid: twitter_user.uid,
                screen_name: twitter_user.screen_name,
                friend_uids: twitter_user.friend_uids
            }
        )
      end
    end
  end
end
