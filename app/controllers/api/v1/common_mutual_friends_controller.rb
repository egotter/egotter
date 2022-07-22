module Api
  module V1
    class CommonMutualFriendsController < ::Api::V1::Base

      private

      def summary_uids(limit: SUMMARY_LIMIT)
        return [[], 0] unless user_signed_in? && current_user.twitter_user
        uids = @twitter_user.common_mutual_friend_uids(current_user.twitter_user)
        [uids.take(limit), uids.size]
      end

      def list_uids
        if user_signed_in? && current_user.twitter_user
          @twitter_user.common_mutual_friend_uids(current_user.twitter_user)
        else
          []
        end
      end
    end
  end
end