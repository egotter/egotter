module Api
  module V1
    class UnfriendsController < ::Api::V1::Base

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        relation = @twitter_user.unfriendships
        [relation.limit(limit).pluck(:friend_uid), relation.size]
      end

      def list_users
        @twitter_user.unfriends
      end
    end
  end
end