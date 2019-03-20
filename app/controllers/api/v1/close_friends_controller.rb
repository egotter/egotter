module Api
  module V1
    class CloseFriendsController < ::Api::V1::Base

      private

      def summary_uids(limit: 3)
        uids = @twitter_user.close_friendships.limit(limit).pluck(:friend_uid)
        size = @twitter_user.close_friendships.size
        [uids, size]
      end

      def list_users
        @twitter_user.close_friends
      end
    end
  end
end