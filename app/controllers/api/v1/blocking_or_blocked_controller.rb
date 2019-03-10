module Api
  module V1
    class BlockingOrBlockedController < ::Api::Base

      private

      def summary_uids(limit: 3)
        uids = @twitter_user.blocking_or_blocked_uids
        [uids.take(limit), uids.size]
      end

      def list_users
        @twitter_user.blocking_or_blocked
      end
    end
  end
end
