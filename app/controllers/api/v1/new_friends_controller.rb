module Api
  module V1
    class NewFriendsController < ::Api::Base

      private

      def summary_uids
        @twitter_user.new_friend_uids
      end
    end
  end
end