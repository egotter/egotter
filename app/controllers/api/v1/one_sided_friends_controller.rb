module Api
  module V1
    class OneSidedFriendsController < ::Api::Base

      private

      def summary_uids
        @twitter_user.one_sided_friend_uids
      end
    end
  end
end