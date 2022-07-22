module Api
  module V1
    class UnfollowersController < ::Api::BaseController

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        resources = @twitter_user.unfollowerships
        [resources.limit(limit).pluck(:follower_uid), resources.size]
      end

      def list_uids
        @twitter_user.unfollower_uids
      end
    end
  end
end