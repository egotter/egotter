module Api
  module V1
    class RepliedController < ::Api::Base

      private

      def summary_uids
        @twitter_user.replied_uids(login_user: current_user)
      end
    end
  end
end