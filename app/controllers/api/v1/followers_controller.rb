module Api
  module V1
    class FollowersController < ::Api::V1::Base

      private

      def summary_uids(limit: 3)
        uids = @twitter_user.follower_uids.take(limit)
        size = @twitter_user.follower_uids.size
        [uids, size]
      end

      def list_users
        @twitter_user.followers
      end
    end
  end
end