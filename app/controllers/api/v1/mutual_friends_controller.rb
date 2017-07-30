module Api
  module V1
    class MutualFriendsController < ::Api::Base

      private

      def summary_uids
        @twitter_user.mutual_friend_uids
      end
    end
  end
end