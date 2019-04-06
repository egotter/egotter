class NotFoundController < ApplicationController

  before_action :valid_screen_name?
  before_action :not_found_screen_name?
  before_action :create_search_log

  def show
    @screen_name = params[:screen_name]
    @user = TwitterDB::User.find_by(screen_name: @screen_name)
    @user = TwitterUser.latest_by(screen_name: @screen_name) unless @user

    flash.now[:alert] = not_found_message(@screen_name)

    if @user
      render status: :not_found
    else
      render 'really_not_found', status: :not_found
    end
  end

  private

  def not_found_screen_name?
    if NotFoundUser.exists?(screen_name: params[:screen_name]) || not_found_user?(params[:screen_name])
      true
    else
      redirect_to timeline_path(screen_name: params[:screen_name])
      false
    end
  end
end
