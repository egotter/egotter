module Api
  module V1
    class ReplyingController < ::Api::Base

      private

      def summary_uids(limit: 3)
        uids = @twitter_user.replying_uids
        [uids.take(limit), uids.size]
      end

      def list_uids(min_sequence, limit: 10)
        uids = @twitter_user.replying_uids.slice(min_sequence, limit)
        if uids.blank?
          [[], -1]
        else
          [uids, min_sequence + uids.size - 1]
        end
      end
    end
  end
end