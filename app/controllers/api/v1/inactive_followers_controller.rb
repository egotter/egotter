module Api
  module V1
    class InactiveFollowersController < ::Api::V1::Base

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        uids = @twitter_user.inactive_followerships.limit(limit).pluck(:follower_uid)
        size = @twitter_user.inactive_followerships.size
        [uids, size]
      end

      def list_users
        @twitter_user.inactive_followers
      end
    end
  end
end