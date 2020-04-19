module Api
  module V1
    class BlockingOrBlockedController < ::Api::V1::Base

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        relation = @twitter_user.block_friendships
        [relation.limit(limit).pluck(:friend_uid), relation.size]
      end

      def list_users
        @twitter_user.block_friends
      end
    end
  end
end
