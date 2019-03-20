module Api
  module V1
    class UnfollowersController < ::Api::V1::Base

      private

      def summary_uids(limit: 3)
        relation = @twitter_user.unfollowerships
        [relation.limit(limit).pluck(:follower_uid), relation.size]
      end

      def list_users
        @twitter_user.unfollowers
      end
    end
  end
end