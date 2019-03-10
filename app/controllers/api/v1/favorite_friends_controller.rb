module Api
  module V1
    class FavoriteFriendsController < ::Api::Base

      private

      def summary_uids(limit: 3)
        uids = @twitter_user.favorite_friendships.limit(limit).pluck(:friend_uid)
        size = @twitter_user.favorite_friendships.size
        [uids, size]
      end

      def list_users
        @twitter_user.favorite_friends
      end
    end
  end
end