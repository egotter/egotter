module Api
  module V1
    class UnfollowersController < ::Api::Base

      private

      def summary_uids
        @twitter_user.removed_uids
      end
    end
  end
end