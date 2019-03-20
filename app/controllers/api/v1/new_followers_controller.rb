module Api
  module V1
    class NewFollowersController < ::Api::V1::Base

      private

      def summary_uids(limit: 3)
        uids = @twitter_user.follower_uids.take(limit)
        size = @twitter_user.follower_uids.size
        [uids, size]
      end
    end
  end
end