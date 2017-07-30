module Api
  module V1
    class BlockingOrBlockedController < ::Api::Base

      private

      def summary_uids
        @twitter_user.blocking_or_blocked_uids
      end
    end
  end
end