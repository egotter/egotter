module Api
  module V1
    class SummariesController < ApplicationController

      layout false

      before_action { self.access_log_disabled = true }
      before_action { head :forbidden if twitter_dm_crawler? }
      before_action { head :forbidden unless request.headers['HTTP_X_CSRF_TOKEN'] }

      before_action { valid_uid?(params[:uid]) }
      before_action { twitter_user_persisted?(params[:uid]) }
      before_action { @twitter_user = TwitterUser.with_delay.latest_by(uid: params[:uid]) }
      before_action { !protected_search?(@twitter_user) }

      def show
        render json: {
            one_sided_friends: @twitter_user.one_sided_friendships.size,
            one_sided_followers: @twitter_user.one_sided_followerships.size,
            mutual_friends: @twitter_user.mutual_friendships.size,
            unfriends: @twitter_user.unfriends_size,
            unfollowers: @twitter_user.unfollowers_size,
            mutual_unfriends: @twitter_user.mutual_unfriendships.size,
        }
      end
    end
  end
end
