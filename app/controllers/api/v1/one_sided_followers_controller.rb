module Api
  module V1
    class OneSidedFollowersController < ::Api::V1::Base

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        uids = @twitter_user.one_sided_followerships.limit(limit).pluck(:follower_uid)
        size = @twitter_user.one_sided_followerships.size
        [uids, size]
      end

      def list_users
        @twitter_user.one_sided_followers
      end
    end
  end
end