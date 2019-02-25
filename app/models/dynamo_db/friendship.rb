# -*- SkipSchemaAnnotations
module DynamoDB
  class Friendship
    extend DynamoDB::Util

    self.table_name = "egotter.#{Rails.env}.friendships"

    class << self
      def find_by(twitter_user_id:)
        item = client.get_item(table_name: table_name, key: {twitter_user_id: twitter_user_id}).item
        return {} unless item
        {
            twitter_user_id: item['twitter_user_id'],
            uid: item['uid'],
            screen_name: item['screen_name'],
            friend_uids: item['friend_uids']
        }
      end

      def import_by!(twitter_user:)
        import_from!(twitter_user.id, twitter_user.uid, twitter_user.screen_name, twitter_user.friend_uids)
      end

      def import_from!(twitter_user_id, uid, screen_name, friend_uids)
        client.put_item(
            table_name: table_name,
            item: {
                twitter_user_id: twitter_user_id,
                uid: uid,
                screen_name: screen_name,
                friend_uids: friend_uids
            }
        )
      end
    end
  end
end
