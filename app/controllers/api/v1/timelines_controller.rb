module Api
  module V1
    class TimelinesController < ApplicationController

      layout false

      before_action { head :forbidden if twitter_dm_crawler? }
      before_action { head :forbidden unless request.xhr? }
      before_action { head :forbidden if request.referer.blank? }
      before_action { head :forbidden unless request.headers['HTTP_X_CSRF_TOKEN'] }

      before_action { valid_uid?(params[:uid]) }
      before_action { twitter_user_persisted?(params[:uid]) }
      before_action { @twitter_user = TwitterUser.with_delay.latest_by(uid: params[:uid]) }

      include JobQueueingConcern
      include SearchHistoriesConcern

      before_action do
        create_search_history(@twitter_user)
        if user_signed_in?
          unless (@jid = request_creating_twitter_user(@twitter_user.uid))
            request_assembling_twitter_user(@twitter_user)
          end
        end
      end

      def show
        render json: {html: render_to_string(formats: [:html])}
      end
    end
  end
end
