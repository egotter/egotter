# -*- SkipSchemaAnnotations
module TwitterDB
  module S3
    module Api
      def find_by(uid:)
        find_by_current_scope(uids_key, :uid, uid)
      end

      def import_by!(user:)
        import_from!(user.uid, user.screen_name, user.send(uids_key))
      end

      def import_from!(uid, screen_name, uids)
        store(uid, encoded_body(uid, screen_name, uids))
      end


      def import!(users)
        users.each {|user| user.send(uids_key)}
        parallel(users) {|user| import_by!(user: user)}
      end

      def delete_cache_by(uid:)
        delete_cache(uid)
      end

      def encoded_body(uid, screen_name, uids)
        {
            uid: uid,
            screen_name: screen_name,
            uids_key => pack(uids),
            compress: 1
        }.to_json
      end
    end

    module ProfileApi
      def profile_key
        :user_info
      end

      def find_by(uid:)
        find_by_current_scope(profile_key, :uid, uid)
      end

      def import_by!(twitter_db_user:)
        import_from!(twitter_db_user.uid, twitter_db_user.screen_name, twitter_db_user.send(profile_key))
      end

      def import_from!(uid, screen_name, profile)
        store(uid, encoded_body(uid, screen_name, profile))
      end


      def import!(twitter_db_users)
        parallel(twitter_db_users) {|user| import_by!(twitter_db_user: user)}
      end

      def delete_cache_by(uid:)
        delete_cache(uid)
      end

      def encoded_body(uid, screen_name, profile)
        {
            uid: uid,
            screen_name: screen_name,
            profile_key => pack(profile),
            compress: 1
        }.to_json
      end
    end
  end
end
