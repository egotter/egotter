module Api
  module V1
    class NewFollowersController < ::Api::BaseController

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        uids = @twitter_user.follower_uids.take(limit)
        size = @twitter_user.follower_uids.size
        [uids, size]
      end
    end
  end
end