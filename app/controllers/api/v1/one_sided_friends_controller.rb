module Api
  module V1
    class OneSidedFriendsController < ::Api::BaseController

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        uids = @twitter_user.one_sided_friendships.limit(limit).pluck(:friend_uid)
        size = @twitter_user.one_sided_friendships.size
        [uids, size]
      end

      def list_uids
        @twitter_user.one_sided_friend_uids
      end
    end
  end
end