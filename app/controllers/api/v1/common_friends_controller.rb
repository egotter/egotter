module Api
  module V1
    class CommonFriendsController < ::Api::Base

      private

      def summary_uids(limit: 3)
        return [[], 0] unless current_user.twitter_user
        uids = @twitter_user.common_friend_uids(current_user.twitter_user)
        [uids.take(limit), uids.size]
      end

      def list_uids(min_sequence, limit: 10)
        return [[], -1] unless current_user.twitter_user
        uids = @twitter_user.common_friend_uids(current_user.twitter_user).slice(min_sequence, limit)
        if uids.blank?
          [[], -1]
        else
          [uids, min_sequence + uids.size - 1]
        end
      end
    end
  end
end