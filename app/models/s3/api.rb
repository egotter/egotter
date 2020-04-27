# -*- SkipSchemaAnnotations
module S3
  module Api
    include Util

    def exists?(twitter_user_id:)
      exist(twitter_user_id)
    end

    def find_by(twitter_user_id:)
      result = find_by_current_scope(payload_key, :twitter_user_id, twitter_user_id)
      result ? new(result) : nil
    end

    def delete_by(twitter_user_id:)
      delete(twitter_user_id)
    end

    def import_from!(twitter_user_id, uid, screen_name, uids, async: true)
      body = encoded_body(twitter_user_id, uid, screen_name, uids)
      store(twitter_user_id, body, async: async)
    end

    def encoded_body(twitter_user_id, uid, screen_name, uids)
      {
          twitter_user_id: twitter_user_id,
          uid: uid,
          screen_name: screen_name,
          payload_key => pack(uids),
          compress: 1
      }.to_json
    end
  end
end
