module Api
  module V1
    class TimelinesController < ApplicationController
      include ApiRequestConcern

      before_action { self.access_log_disabled = true }

      def summary
        render json: {
            one_sided_friends: @twitter_user.one_sided_friendships.size,
            one_sided_followers: @twitter_user.one_sided_followerships.size,
            mutual_friends: @twitter_user.mutual_friendships.size,
            unfriends: @twitter_user.unfriendships.size,
            unfollowers: @twitter_user.unfollowerships.size,
            blocking_or_blocked: @twitter_user.mutual_unfriendships.size
        }
      end

      def profile
        html = render_to_string(partial: 'twitter/profile', locals: {user: @twitter_user, always_expanded: params['expanded'] == 'true'}, formats: [:html])
        render json: {html: html}
      end
    end
  end
end
