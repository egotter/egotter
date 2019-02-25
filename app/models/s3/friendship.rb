# -*- SkipSchemaAnnotations
module S3
  class Friendship
    extend S3::Util

    self.bucket_name = "egotter.#{Rails.env}.friendships"

    class << self
      def find_by(twitter_user_id:)
        text = client.get_object(bucket: bucket_name, key: twitter_user_id.to_s).body.read
        item = Oj.load(text)
        {
            twitter_user_id: item['twitter_user_id'],
            uid: item['uid'],
            screen_name: item['screen_name'],
            friend_uids: item['friend_uids']
        }
      rescue Aws::S3::Errors::NoSuchKey => e
        Rails.logger.debug {"#{e.class} #{e.message} #{twitter_user_id}"}
        {}
      end

      def import_by!(twitter_user:)
        import_from!(twitter_user.id, twitter_user.uid, twitter_user.screen_name, twitter_user.friend_uids)
      end

      def import_from!(twitter_user_id, uid, screen_name, friend_uids)
        client.put_object(
            bucket: bucket_name,
            body: {
                twitter_user_id: twitter_user_id,
                uid: uid,
                screen_name: screen_name,
                friend_uids: friend_uids
            }.to_json,
            key: twitter_user_id.to_s
        )
      end
    end
  end
end
