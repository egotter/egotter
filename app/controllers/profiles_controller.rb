class ProfilesController < ApplicationController
  before_action :valid_screen_name?

  before_action do
    self.sidebar_disabled = true
  end

  def show
    @user = TwitterDB::User.find_by(screen_name: params[:screen_name])
    @user = TwitterUser.latest_by(screen_name: params[:screen_name]) unless @user

    @screen_name = params[:screen_name]
  end
end
