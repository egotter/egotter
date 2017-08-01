module Api
  module V1
    class OneSidedFollowersController < ::Api::Base

      private

      def summary_uids(limit: 3)
        uids = @twitter_user.one_sided_followerships.limit(limit).pluck(:follower_uid)
        size = @twitter_user.one_sided_followerships.size
        [uids, size]
      end
    end
  end
end