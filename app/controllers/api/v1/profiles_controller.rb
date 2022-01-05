module Api
  module V1
    class ProfilesController < ApplicationController

      layout false

      before_action { head :forbidden if twitter_dm_crawler? }
      before_action { head :forbidden unless request.xhr? }
      before_action { head :forbidden if request.referer.blank? }
      before_action { head :forbidden unless request.headers['HTTP_X_CSRF_TOKEN'] }

      before_action { valid_uid?(params[:uid]) }
      before_action { set_user(params[:uid]) }

      def show
        html = render_to_string(partial: 'twitter/profile', locals: {user: @user}, formats: [:html])
        render json: {html: html}
      end

      private

      def set_user(uid)
        unless (@user = TwitterDB::User.find_by(uid: uid))
          head :not_found
        end
      end
    end
  end
end
