module Api
  module V1
    class InactiveFriendsController < ::Api::V1::Base

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        uids = @twitter_user.inactive_friendships.limit(limit).pluck(:friend_uid)
        size = @twitter_user.inactive_friendships.size
        [uids, size]
      end

      def list_users
        @twitter_user.inactive_friends
      end
    end
  end
end