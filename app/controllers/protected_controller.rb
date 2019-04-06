class ProtectedController < ApplicationController

  before_action :valid_screen_name?
  before_action :protected_screen_name?
  before_action :create_search_log

  def show
    @screen_name = params[:screen_name]
    @user = TwitterDB::User.find_by(screen_name: @screen_name)
    @user = TwitterUser.latest_by(screen_name: @screen_name) unless @user

    flash.now[:alert] = protected_message(@screen_name)

    if @user
      render 'not_found/show'
    else
      render 'not_found/really_not_found'
    end
  end

  private

  def protected_screen_name?
    if protected_user?(params[:screen_name])
      true
    else
      redirect_to timeline_path(screen_name: params[:screen_name])
      false
    end
  end
end
