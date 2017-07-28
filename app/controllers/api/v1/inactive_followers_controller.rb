module Api
  module V1
    class InactiveFollowersController < ::Api::Base

      private

      def summary_uids
        @twitter_user.inactive_follower_uids
      end
    end
  end
end