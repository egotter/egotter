module Api
  module V1
    class MutualUnfriendsController < ::Api::V1::Base

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        resources = @twitter_user.mutual_unfriendships
        [resources.limit(limit).pluck(:friend_uid), resources.size]
      end

      def list_users
        @twitter_user.mutual_unfriends(limit: api_list_users_limit)
      end
    end
  end
end
