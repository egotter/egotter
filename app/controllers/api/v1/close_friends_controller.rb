module Api
  module V1
    class CloseFriendsController < ::Api::Base

      private

      def summary_uids
        @twitter_user.close_friend_uids
      end
    end
  end
end