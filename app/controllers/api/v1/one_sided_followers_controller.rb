module Api
  module V1
    class OneSidedFollowersController < ::Api::Base

      private

      def summary_uids
        @twitter_user.one_sided_follower_uids
      end
    end
  end
end