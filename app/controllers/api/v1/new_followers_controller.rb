module Api
  module V1
    class NewFollowersController < ::Api::Base

      private

      def summary_uids(limit: 3)
        uids = @twitter_user.followerships.limit(limit).pluck(:follower_uid)
        size = @twitter_user.followerships.size
        [uids, size]
      end
    end
  end
end