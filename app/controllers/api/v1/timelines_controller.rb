module Api
  module V1
    class TimelinesController < ApplicationController

      layout false

      before_action { head :forbidden unless request.headers['HTTP_X_CSRF_TOKEN'] }
      before_action { self.access_log_disabled = true }

      before_action { valid_uid?(params[:uid]) }
      before_action { twitter_db_user_persisted?(params[:uid]) }
      before_action(only: %i(show summary)) { twitter_user_persisted?(params[:uid]) }
      before_action(only: %i(show summary)) { @twitter_user = TwitterUser.with_delay.latest_by(uid: params[:uid]) }
      before_action(only: %i(show summary)) { !protected_search?(@twitter_user) }

      def show
        render json: {html: render_to_string(formats: [:html])}
      end

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
        if (user = TwitterDB::User.find_by(uid: params[:uid]))
          html = render_to_string(partial: 'twitter/profile', locals: {user: user, always_expanded: params['expanded'] == 'true'}, formats: [:html])
          render json: {html: html}
        else
          render json: {error: 'not found'}, status: :not_found
        end
      end
    end
  end
end
