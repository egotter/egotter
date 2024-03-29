module Api
  module V1
    class UnfriendsController < ::Api::BaseController

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        resources = @twitter_user.unfriendships
        [resources.limit(limit).pluck(:friend_uid), resources.size]
      end

      def list_uids
        @twitter_user.unfriend_uids
      end
    end
  end
end