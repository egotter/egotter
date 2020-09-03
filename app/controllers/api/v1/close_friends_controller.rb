module Api
  module V1
    class CloseFriendsController < ::Api::V1::Base

      def show
        CreateCloseFriendsOgImageWorker.perform_async(@twitter_user.uid) unless from_crawler?
        summary
      end

      private

      # The heart shape is made up of 65 squares
      CLOSE_FRIENDS_SUMMARY_LIMIT = 70

      def summary_uids(*)
        uids = @twitter_user.close_friend_uids.take(CLOSE_FRIENDS_SUMMARY_LIMIT)
        size = @twitter_user.close_friend_uids.size
        [uids, size]
      end

      def list_users
        @twitter_user.close_friends
      end
    end
  end
end