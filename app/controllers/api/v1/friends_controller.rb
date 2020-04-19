module Api
  module V1
    class FriendsController < ::Api::V1::Base

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        uids = @twitter_user.friend_uids.take(limit)
        size = @twitter_user.friend_uids.size
        [uids, size]
      end

      def list_users
        @twitter_user.friends
      end
    end
  end
end