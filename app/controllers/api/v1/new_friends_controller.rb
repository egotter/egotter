module Api
  module V1
    class NewFriendsController < ::Api::Base

      private

      def summary_uids(limit: 3)
        uids = @twitter_user.friend_uids.take(limit)
        size = @twitter_user.friend_uids.size
        [uids, size]
      end
    end
  end
end