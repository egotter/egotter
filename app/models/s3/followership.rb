# -*- SkipSchemaAnnotations
module S3
  class Followership
    extend S3::Util

    self.bucket_name = "egotter.#{Rails.env}.followerships"

    class << self
      def find_by(twitter_user_id:)
        text = client.get_object(bucket: bucket_name, key: twitter_user_id.to_s).body.read
        item = parse_json(text)
        follower_uids = item.has_key?('compress') ? parse_json(decompress(Base64.decode64(item['follower_uids']))) : item['follower_uids']
        {
            twitter_user_id: item['twitter_user_id'],
            uid: item['uid'],
            screen_name: item['screen_name'],
            follower_uids: follower_uids
        }
      rescue Aws::S3::Errors::NoSuchKey => e
        Rails.logger.debug {"#{e.class} #{e.message} #{twitter_user_id}"}
        {}
      end

      def import_by!(twitter_user:)
        import_from!(twitter_user.id, twitter_user.uid, twitter_user.screen_name, twitter_user.follower_uids)
      end

      def import_from!(twitter_user_id, uid, screen_name, follower_uids)
        client.put_object(
            bucket: bucket_name,
            body: encoded_body(twitter_user_id, uid, screen_name, follower_uids),
            key: twitter_user_id.to_s
        )
      end

      def encoded_body(twitter_user_id, uid, screen_name, uids)
        {
            twitter_user_id: twitter_user_id,
            uid: uid,
            screen_name: screen_name,
            follower_uids: Base64.encode64(compress(uids.to_json)),
            compress: 1
        }.to_json
      end
    end
  end
end
