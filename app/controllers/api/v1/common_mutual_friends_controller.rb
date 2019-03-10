module Api
  module V1
    class CommonMutualFriendsController < ::Api::Base

      private

      def summary_uids(limit: 3)
        return [[], 0] unless user_signed_in? && current_user.twitter_user
        uids = @twitter_user.common_mutual_friend_uids(current_user.twitter_user)
        [uids.take(limit), uids.size]
      end

      def list_users
        if user_signed_in? && current_user.twitter_user
          @twitter_user.common_mutual_friends(current_user.twitter_user)
        else
          []
        end
      end
    end
  end
end