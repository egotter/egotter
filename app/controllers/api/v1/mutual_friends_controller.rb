module Api
  module V1
    class MutualFriendsController < ::Api::Base

      private

      def summary_uids(limit: 3)
        uids = @twitter_user.mutual_friendships.limit(limit).pluck(:friend_uid)
        size = @twitter_user.mutual_friendships.size
        [uids, size]
      end
    end
  end
end