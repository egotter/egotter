module Api
  module V1
    class ReplyingController < ::Api::Base

      private

      def summary_uids
        @twitter_user.replying_uids
      end
    end
  end
end