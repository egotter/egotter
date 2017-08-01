module Api
  module V1
    class UnfriendsController < ::Api::Base

      private

      def summary_uids(limit: 3)
        uids = @twitter_user.unfriendships.limit(limit).pluck(:friend_uid)
        size = @twitter_user.unfriendships.size
        [uids, size]
      end
    end
  end
end