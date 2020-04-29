class ProfilesController < ApplicationController
  before_action :valid_screen_name?

  before_action only: :latest do
    request_context_client.user(params[:screen_name])
  rescue => e
    notify_airbrake(e)
  else
    DeleteNotFoundUserWorker.new.perform(params[:screen_name])
    DeleteForbiddenUserWorker.new.perform(params[:screen_name])
  end

  before_action unless: :twitter_crawler? do
    !not_found_screen_name? && !forbidden_screen_name?
  end
  before_action :create_search_log

  def show
    self.sidebar_disabled = true
    @user = TwitterDB::User.find_by(screen_name: params[:screen_name])
    @user = TwitterUser.latest_by(screen_name: params[:screen_name]) unless @user
    @user = build_twitter_user_by(screen_name: params[:screen_name]) unless @user # It's possible to be redirected
    return if performed?
    @display_time = l((@user.updated_at || Time.zone.now).in_time_zone('Tokyo'), format: :profile_short)
  end

  def latest
    self.sidebar_disabled = true
    @user = build_twitter_user_by(screen_name: params[:screen_name]) # It's possible to be redirected
  end

  private

  def updated_at_message(user)
    url = latest_profile_path(screen_name: user.screen_name, via: current_via('request_to_update'))
    time = user.updated_at || Time.zone.now
    format = (time.in_time_zone('Tokyo').to_date === Time.zone.now.in_time_zone('Tokyo').to_date) ? :next_creation_short : :next_creation_long
    t("profiles.#{action_name}.displayed_data_is_html", user: user.screen_name, url: url, time: l(time.in_time_zone('Tokyo'), format: format))
  end
end
