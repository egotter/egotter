# -*- SkipSchemaAnnotations
module S3
  module ProfileApi
    include Util

    def exists?(twitter_user_id:)
      exist(twitter_user_id)
    end

    def find_by(twitter_user_id:)
      find_by_current_scope(payload_key, :twitter_user_id, twitter_user_id)
    end

    def delete_by(twitter_user_id:)
      delete(twitter_user_id)
    end

    def import_from!(twitter_user_id, uid, screen_name, profile, async: true)
      body = encoded_body(twitter_user_id, uid, screen_name, profile)
      store(twitter_user_id, body, async: async)
    end

    def encoded_body(twitter_user_id, uid, screen_name, profile)
      {
          twitter_user_id: twitter_user_id,
          uid: uid,
          screen_name: screen_name,
          payload_key => pack(profile),
          compress: 1
      }.to_json
    end
  end
end
