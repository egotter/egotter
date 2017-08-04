module Api
  module V1
    class FollowersController < ::Api::Base

      private

      def summary_uids(limit: 3)
        uids = @twitter_user.followerships.limit(limit).pluck(:follower_uid)
        size = @twitter_user.followerships.size
        [uids, size]
      end

      def list_uids(min_sequence, limit: 10)
        followerships = @twitter_user.followerships.where("sequence >= ?", min_sequence).limit(limit)
        if followerships.empty?
          [[], -1]
        else
          [followerships.map(&:follower_uid), followerships.last.sequence]
        end
      end
    end
  end
end