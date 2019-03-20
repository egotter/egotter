module Api
  module V1
    class InactiveMutualFriendsController < ::Api::V1::Base

      private

      def summary_uids(limit: 3)
        uids = @twitter_user.inactive_mutual_friendships.limit(limit).pluck(:friend_uid)
        size = @twitter_user.inactive_mutual_friendships.size
        [uids, size]
      end

      def list_users
        @twitter_user.inactive_mutual_friends
      end
    end
  end
end