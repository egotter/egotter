module Api
  module V1
    class InactiveFriendsController < ::Api::V1::Base

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        uids = @twitter_user.inactive_friendships.limit(limit).pluck(:friend_uid)
        size = @twitter_user.inactive_friendships.size
        [uids, size]
      end

      def list_users
        limit = user_signed_in? && current_user.has_valid_subscription? ? Order::BASIC_PLAN_USERS_LIMIT : Order::FREE_PLAN_USERS_LIMIT
        @twitter_user.inactive_friends(limit: limit)
      end
    end
  end
end