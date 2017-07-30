module Api
  module V1
    class InactiveFriendsController < ::Api::Base

      private

      def summary_uids
        @twitter_user.inactive_friend_uids
      end
    end
  end
end