module Api
  module V1
    class RepliedController < ::Api::V1::Base

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        uids = @twitter_user.replied_uids(login_user: current_user)
        [uids.take(limit), uids.size]
      end

      def list_users
        @twitter_user.replied(login_user: current_user)
      end

      def list_uids
        @twitter_user.replied_uids(login_user: current_user)
      end
    end
  end
end