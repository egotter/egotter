module Admin
  class SettingsController < ApplicationController

    before_action :require_admin!

    def follow_requests
      @requests = fetch_user.follow_requests.limit(20)
      render template: 'settings/follow_requests'
    end

    def unfollow_requests
      @requests = fetch_user.unfollow_requests.limit(20)
      render template: 'settings/unfollow_requests'
    end

    private

    def fetch_user
      User.find(params[:user_id])
    end
  end
end
