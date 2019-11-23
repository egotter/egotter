class ProfilesController < ApplicationController
  before_action { valid_screen_name? && !not_found_screen_name? && !forbidden_screen_name? }
  before_action :create_search_log

  def show
    self.sidebar_disabled = true

    @twitter_user = build_twitter_user_by(screen_name: params[:screen_name])
  end
end
