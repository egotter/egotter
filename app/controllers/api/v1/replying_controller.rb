module Api
  module V1
    class ReplyingController < ::Api::Base

      private

      def summary_uids(limit: 3)
        uids = @twitter_user.replying_uids
        [uids.take(limit), uids.size]
      end
    end
  end
end