module Api
  module V1
    class TimelinesController < ApplicationController

      layout false

      before_action { head :forbidden unless request.headers['HTTP_X_CSRF_TOKEN'] }
      before_action { self.access_log_disabled = true }

      before_action { valid_uid?(params[:uid]) }
      before_action { twitter_user_persisted?(params[:uid]) }
      before_action { @twitter_user = TwitterUser.with_delay.latest_by(uid: params[:uid]) }
      before_action { !protected_search?(@twitter_user) }

      def show
        render json: {html: render_to_string(formats: [:html])}
      end
    end
  end
end
