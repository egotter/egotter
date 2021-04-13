class BlockersController < ApplicationController
  include BlockersConcern

  before_action { head :forbidden if twitter_dm_crawler? }
  before_action :authenticate_user!
  before_action :set_twitter_user
  before_action :search_yourself!
  before_action :has_subscription!

  def index
  end

  private

  def set_twitter_user
    unless (@twitter_user = TwitterUser.latest_by(uid: current_user.uid))
      session[:screen_name] = current_user.screen_name
      redirect_to error_pages_twitter_user_not_persisted_path(via: current_via)
    end
  end
end
