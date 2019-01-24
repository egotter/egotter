module Api
  module V1
    class OneSidedFollowersController < ::Api::Base

      private

      def summary_uids(limit: 3)
        uids = @twitter_user.one_sided_followerships.limit(limit).pluck(:follower_uid)
        size = @twitter_user.one_sided_followerships.size
        [uids, size]
      end

      def list_uids(min_sequence, limit:)
        followerships = @twitter_user.one_sided_followerships.where("sequence >= ?", min_sequence).limit(limit)
        if followerships.empty?
          [[], -1]
        else
          [followerships.map(&:follower_uid), followerships.last.sequence]
        end
      end

      def list_users
        @twitter_user.one_sided_followers
      end
    end
  end
end