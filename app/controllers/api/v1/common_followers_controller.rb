module Api
  module V1
    class CommonFollowersController < ::Api::Base

      before_action :require_login!

      private

      def summary_uids(limit: 3)
        return [[], 0] unless current_user.twitter_user
        uids = @twitter_user.common_follower_uids(current_user.twitter_user)
        [uids.take(limit), uids.size]
      end

      def list_uids(min_sequence, limit:)
        return [[], -1] unless current_user.twitter_user
        uids = @twitter_user.common_follower_uids(current_user.twitter_user).slice(min_sequence, limit)
        if uids.blank?
          [[], -1]
        else
          [uids, min_sequence + uids.size - 1]
        end
      end

      def list_users
        return [[], -1] unless current_user.twitter_user
        @twitter_user.common_followers(current_user.twitter_user)
      end
    end
  end
end