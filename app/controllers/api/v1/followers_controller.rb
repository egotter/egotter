module Api
  module V1
    class FollowersController < ::Api::V1::Base

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        uids = @twitter_user.follower_uids.take(limit)
        size = @twitter_user.follower_uids.size
        [uids, size]
      end

      def list_users
        @twitter_user.followers(limit: api_list_users_limit)
      end

      def list_uids
        @twitter_user.follower_uids
      end
    end
  end
end