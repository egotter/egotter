class ForbiddenController < ApplicationController

  before_action :valid_screen_name?
  before_action :forbidden_screen_name?
  before_action :create_search_log

  def show
    @screen_name = params[:screen_name]
    @user = TwitterDB::User.find_by(screen_name: @screen_name)
    @user = TwitterUser.latest_by(screen_name: @screen_name) unless @user

    # Even if this value is not set, the sidebar will not be displayed because @twitter_user is not set.
    self.sidebar_disabled = true

    flash.now[:alert] = forbidden_message(@screen_name)

    if @user
      render 'not_found/show'
    else
      render 'not_found/really_not_found'
    end
  end

  private

  def forbidden_screen_name?
    if ForbiddenUser.exists?(screen_name: params[:screen_name]) || forbidden_user?(params[:screen_name])
      true
    else
      redirect_to timeline_path(screen_name: params[:screen_name])
      false
    end
  end
end
