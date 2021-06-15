module Api
  module V1
    class BannedUsersController < ApplicationController

      skip_before_action :current_user_not_blocker?

      before_action :reject_crawler
      before_action :require_login!
      before_action :has_valid_subscription!

      def destroy
        BannedUser.find_by(user_id: current_user.id).destroy
        render json: {message: t('.success_html', count: 3), interval: 3}
      end
    end
  end
end
