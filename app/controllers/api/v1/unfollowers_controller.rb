module Api
  module V1
    class UnfollowersController < ::Api::Base

      private

      def summary_uids(limit: 3)
        uids = @twitter_user.unfollowerships.limit(limit).pluck(:follower_uid)
        size = @twitter_user.unfollowerships.size
        [uids, size]
      end
    end
  end
end