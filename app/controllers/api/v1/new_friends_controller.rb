module Api
  module V1
    class NewFriendsController < ::Api::Base

      private

      def summary_uids(limit: 3)
        uids = @twitter_user.friendships.limit(limit).pluck(:friend_uid)
        size = @twitter_user.friendships.size
        [uids, size]
      end
    end
  end
end