module Admin
  class SettingsController < ApplicationController

    before_action :require_admin!
    before_action :create_search_log

    def follow_requests
      @requests = fetch_user.follow_requests.limit(20)
      render template: 'settings/follow_requests'
    end

    def unfollow_requests
      @requests = fetch_user.unfollow_requests.limit(20)
      render template: 'settings/unfollow_requests'
    end

    def create_prompt_report_requests
      @requests = fetch_user.create_prompt_report_requests.includes(:logs).limit(20)
      render template: 'settings/create_prompt_report_requests'
    end

    private

    def fetch_user
      User.find(params[:user_id])
    end
  end
end
