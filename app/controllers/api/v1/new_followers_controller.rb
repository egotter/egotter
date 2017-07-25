module Api
  module V1
    class NewFollowersController < ::Api::Base

      private

      def summary_uids
        @twitter_user.new_follower_uids
      end
    end
  end
end