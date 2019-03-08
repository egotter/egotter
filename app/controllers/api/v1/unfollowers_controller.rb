module Api
  module V1
    class UnfollowersController < ::Api::Base

      private

      def summary_uids(limit: 3)
        relation = @twitter_user.unfollowerships
        [relation.limit(limit).pluck(:follower_uid), relation.size]
      end

      def list_uids(min_sequence, limit:)
        relation = @twitter_user.unfollowerships.where("sequence >= ?", min_sequence).limit(limit)
        if relation.empty?
          [[], -1]
        else
          [relation.map(&:follower_uid), relation.last.sequence]
        end
      end

      def list_users
        @twitter_user.unfollowers
      end
    end
  end
end