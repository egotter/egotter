class BlockedController < ApplicationController

  before_action :require_login!
  before_action :valid_screen_name?

  before_action do
    if params[:force_update] == 'true'
      # There is nothing I can do at this time.
    end
  end

  before_action do
    if blocked_user?(params[:screen_name])
      true
    else
      via = params[:force_update] == 'true' ? 'blocked_force_update' : 'blocked_redirect'
      redirect_to timeline_path(screen_name: params[:screen_name], via: build_via(via))
      false
    end
  end

  before_action :create_search_log

  def show
    screen_name = params[:screen_name]
    @user = TwitterDB::User.find_by(screen_name: screen_name)
    @user = TwitterUser.latest_by(screen_name: screen_name) unless @user

    # Even if this value is not set, the sidebar will not be displayed because @twitter_user is not set.
    self.sidebar_disabled = true

    flash.now[:alert] = blocked_with_request_message(screen_name, blocked_path(screen_name: screen_name, via: build_via('force_update_message'), force_update: 'true'))
    @user ? render : (render 'not_persisted')
  end
end
