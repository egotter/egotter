class NotificationsController < ApplicationController
  include Logging
  include SearchesHelper

  before_action only: %i(index) do
    create_search_log(action: :notifications)
  end

  def index
    return redirect_to '/' unless user_signed_in?

    @title = t('.title', user: current_user.mention_name)
    @items = NotificationMessage.where(user_id: current_user.id).order(created_at: :desc).limit(10)
  end

  def update
    key, value =
      case
        when params[:email]  then [:email, params[:email]]
        when params[:dm]     then [:dm, params[:dm]]
        when params[:news]   then [:news, params[:news]]
        when params[:search] then [:search, params[:search]]
      end
    value = value == 'true' ? true : false
    current_user.notification_setting.update!(key => value)
    render json: current_user.notification_setting.attributes.slice('email', 'dm', 'news', 'search'), status: 200
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{params.inspect}"
    render nothing: true, status: 500
  end
end
