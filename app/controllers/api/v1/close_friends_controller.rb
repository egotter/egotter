module Api
  module V1
    class CloseFriendsController < ::Api::V1::Base

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        uids = @twitter_user.close_friend_uids.take(limit)
        size = @twitter_user.close_friend_uids.size
        [uids, size]
      end

      def list_users
        @twitter_user.close_friends
      end
    end
  end
end