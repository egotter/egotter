module Api
  module V1
    class FavoriteFriendsController < ::Api::V1::Base

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        uids = @twitter_user.favorite_friend_uids.take(limit)
        size = @twitter_user.favorite_friend_uids.size
        [uids, size]
      end

      def list_uids
        @twitter_user.favorite_friend_uids
      end
    end
  end
end