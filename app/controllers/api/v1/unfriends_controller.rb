module Api
  module V1
    class UnfriendsController < ::Api::Base

      private

      def summary_uids
        @twitter_user.removing_uids
      end
    end
  end
end