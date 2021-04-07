class ProfilesController < ApplicationController

  around_action :disable_newrelic_tracer_for_crawlers
  before_action { head :forbidden if twitter_dm_crawler? }
  before_action :reject_spam_access!
  before_action :valid_screen_name?

  before_action do
    self.sidebar_disabled = true

    if flash.empty? && !@search_count_limitation.count_remaining?
      @without_alert_container = true
      flash.now[:notice] = too_many_searches_message
    end
  end

  def show
    @user = TwitterDB::User.find_by(screen_name: params[:screen_name])
    @user = TwitterUser.latest_by(screen_name: params[:screen_name]) unless @user
    @user = TwitterUserDecorator.new(@user) if @user

    @screen_name = params[:screen_name]

    if params[:names].present? && user_signed_in?
      set_decrypt_names(params[:screen_name], params[:names])
    end
  end

  private

  def set_decrypt_names(name, content)
    @indicator_names = MessageEncryptor.new.decrypt(content).split(',')
  rescue => e
  end
end
