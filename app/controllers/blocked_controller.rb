class BlockedController < ApplicationController

  before_action :require_login!
  before_action :valid_screen_name?
  before_action :blocked_screen_name?
  before_action :create_search_log

  def show
    @screen_name = params[:screen_name]
    @user = TwitterDB::User.find_by(screen_name: @screen_name)
    @user = TwitterUser.latest_by(screen_name: @screen_name) unless @user

    flash.now[:alert] = blocked_message(@screen_name)

    # Even if this value is not set, the sidebar will not be displayed because @twitter_user is not set.
    self.sidebar_disabled = true

    if @user
      render 'not_found/show'
    else
      render 'not_found/really_not_found'
    end
  end

  private

  def blocked_screen_name?
    if blocked_user?(params[:screen_name])
      true
    else
      redirect_to timeline_path(screen_name: params[:screen_name])
      false
    end
  end
end
