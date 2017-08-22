module Api
  module V1
    class UnfollowersController < ::Api::Base

      private

      def summary_uids(limit: 3)
        user = @twitter_user.twitter_db_user
        uids = user.unfollowerships.limit(limit).pluck(:follower_uid)
        size = user.unfollowerships.size
        [uids, size]
      end

      def list_uids(min_sequence, limit: 10)
        followerships = @twitter_user.twitter_db_user.unfollowerships.where("sequence >= ?", min_sequence).limit(limit)
        if followerships.empty?
          [[], -1]
        else
          [followerships.map(&:follower_uid), followerships.last.sequence]
        end
      end
    end
  end
end