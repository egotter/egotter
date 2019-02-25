# -*- SkipSchemaAnnotations
module DynamoDB
  class Followership
    TABLE_NAME = "egotter.#{Rails.env}.followerships"

    class << self
      def client
        @@client ||= Aws::DynamoDB::Client.new(region: REGION)
      end

      def find_by(twitter_user_id:)
        item = client.get_item(table_name: TABLE_NAME, key: {twitter_user_id: twitter_user_id}).item
        return {} unless item
        {
            twitter_user_id: item['twitter_user_id'],
            uid: item['uid'],
            screen_name: item['screen_name'],
            follower_uids: item['follower_uids']
        }
      end

      def import_by!(twitter_user:)
        import_from!(twitter_user.id, twitter_user.uid, twitter_user.screen_name, twitter_user.follower_uids)
      end

      def import_from!(twitter_user_id, uid, screen_name, follower_uids)
        client.put_item(
            table_name: TABLE_NAME,
            item: {
                twitter_user_id: twitter_user_id,
                uid: uid,
                screen_name: screen_name,
                follower_uids: follower_uids
            }
        )
      end
    end
  end
end
