class SettingsController < ApplicationController

  before_action :require_login!
  before_action :create_search_log

  def index
    @delete_tweets_log = DeleteTweetsLog.where(user_id: current_user.id, created_at: 1.hour.ago..Time.zone.now).exists?
    @reset_egotter_log = ResetEgotterLog.where(user_id: current_user.id, status: false).exists?
  end

  def update
    key, value =
      case
        when params[:email]  then [:email,  params[:email]]
        when params[:dm]     then [:dm,     params[:dm]]
        when params[:news]   then [:news,   params[:news]]
        when params[:search] then [:search, params[:search]]
      end
    value = (value == 'true')
    current_user.notification_setting.update!(key => value)
    render json: current_user.notification_setting.attributes.slice('email', 'dm', 'news', 'search')
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{params.inspect}"
    head :internal_server_error
  end

  def follow_requests
    @requests = current_user.follow_requests
  end

  def unfollow_requests
    @requests = current_user.unfollow_requests
  end
end
