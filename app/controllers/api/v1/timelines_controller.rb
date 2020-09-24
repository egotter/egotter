module Api
  module V1
    class TimelinesController < ApplicationController

      layout false

      before_action { self.access_log_disabled = true }
      before_action { head :forbidden if twitter_dm_crawler? }
      before_action { head :forbidden unless request.headers['HTTP_X_CSRF_TOKEN'] }

      before_action { valid_uid?(params[:uid]) }
      before_action { twitter_user_persisted?(params[:uid]) }
      before_action { @twitter_user = TwitterUser.with_delay.latest_by(uid: params[:uid]) }
      before_action { !protected_search?(@twitter_user) }

      include JobQueueingConcern
      include SearchHistoriesConcern

      before_action do
        create_search_history(@twitter_user)
        enqueue_audience_insight(@twitter_user.uid)
        enqueue_assemble_twitter_user(@twitter_user)
        @jid = enqueue_create_twitter_user_job_if_needed(@twitter_user.uid, user_id: current_user_id)
      end

      def show
        render json: {html: render_to_string(formats: [:html])}
      end
    end
  end
end
