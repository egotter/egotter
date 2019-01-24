module Api
  module V1
    class ReplyingAndRepliedController < ::Api::Base

      private

      def summary_uids(limit: 3)
        uids = @twitter_user.replying_and_replied_uids(login_user: current_user)
        [uids.take(limit), uids.size]
      end

      def list_uids(min_sequence, limit:)
        uids = @twitter_user.replying_and_replied_uids(login_user: current_user).slice(min_sequence, limit)
        if uids.blank?
          [[], -1]
        else
          [uids, min_sequence + uids.size - 1]
        end
      end

      def list_users
        @twitter_user.replying_and_replied(login_user: current_user)
      end
    end
  end
end