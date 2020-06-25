module Api
  module V1
    class UnfollowersController < ::Api::V1::Base

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        resources = @twitter_user.unfollowerships
        [resources.limit(limit).pluck(:follower_uid), resources.size]
      end

      def list_users
        @twitter_user.unfollowers
      end
    end
  end
end