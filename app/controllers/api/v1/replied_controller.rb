module Api
  module V1
    class RepliedController < ::Api::Base

      private

      def summary_uids(limit: 3)
        uids = @twitter_user.replied_uids(login_user: current_user)
        [uids.take(limit), uids.size]
      end
    end
  end
end