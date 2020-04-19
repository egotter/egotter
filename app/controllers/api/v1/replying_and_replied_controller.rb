module Api
  module V1
    class ReplyingAndRepliedController < ::Api::V1::Base

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        uids = @twitter_user.replying_and_replied_uids(login_user: current_user)
        [uids.take(limit), uids.size]
      end

      def list_users
        @twitter_user.replying_and_replied(login_user: current_user)
      end
    end
  end
end