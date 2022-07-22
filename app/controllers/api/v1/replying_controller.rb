module Api
  module V1
    class ReplyingController < ::Api::V1::Base

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        uids = @twitter_user.replying_uids
        [uids.take(limit), uids.size]
      end

      def list_uids
        @twitter_user.replying_uids
      end
    end
  end
end