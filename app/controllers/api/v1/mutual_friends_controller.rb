module Api
  module V1
    class MutualFriendsController < ::Api::V1::Base

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        uids = @twitter_user.mutual_friendships.limit(limit).pluck(:friend_uid)
        size = @twitter_user.mutual_friendships.size
        [uids, size]
      end

      def list_users
        @twitter_user.mutual_friends
      end
    end
  end
end