module Api
  module V1
    class NewFriendsController < ::Api::BaseController

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        uids = @twitter_user.friend_uids.take(limit)
        size = @twitter_user.friend_uids.size
        [uids, size]
      end
    end
  end
end