module Api
  module V1
    class OneSidedFriendsController < ::Api::V1::Base

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        uids = @twitter_user.one_sided_friendships.limit(limit).pluck(:friend_uid)
        size = @twitter_user.one_sided_friendships.size
        [uids, size]
      end

      def list_users
        @twitter_user.one_sided_friends(limit: api_list_users_limit)
      end
    end
  end
end