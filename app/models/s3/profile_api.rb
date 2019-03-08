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

    def where(twitter_user_ids:)
      parallel(twitter_user_ids) {|id| find_by(twitter_user_id: id)}
    end

    def delete_by(twitter_user_id:)
      delete(twitter_user_id)
    end

    def import_by!(twitter_user:)
      import_from!(twitter_user.id, twitter_user.uid, twitter_user.screen_name, twitter_user.send(payload_key))
    end

    def import_from!(twitter_user_id, uid, screen_name, profile)
      store(twitter_user_id, encoded_body(twitter_user_id, uid, screen_name, profile))
    end


    def import!(twitter_users)
      parallel(twitter_users) {|user| import_by!(twitter_user: user)}
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
