module Api
  module V1
    class MutualFriendsController < ::Api::BaseController

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        uids = @twitter_user.mutual_friendships.limit(limit).pluck(:friend_uid)
        size = @twitter_user.mutual_friendships.size
        [uids, size]
      end

      def list_uids
        @twitter_user.mutual_friend_uids
      end
    end
  end
end