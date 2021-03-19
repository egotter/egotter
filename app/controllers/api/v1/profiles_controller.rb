module Api
  module V1
    class ProfilesController < ApplicationController

      layout false

      before_action { head :forbidden if twitter_dm_crawler? }
      before_action { head :forbidden unless request.xhr? }
      before_action { head :forbidden if request.referer.blank? }
      before_action { head :forbidden unless request.headers['HTTP_X_CSRF_TOKEN'] }

      before_action { valid_uid?(params[:uid]) }

      def show
        if (user = TwitterDB::User.find_by(uid: params[:uid]))
          html = render_to_string(partial: 'twitter/profile', locals: {user: user, body_expanded: params['expanded'] == 'true'}, formats: [:html])
          render json: {html: html}
        else
          render json: {error: 'not found'}, status: :not_found
        end
      end
    end
  end
end
