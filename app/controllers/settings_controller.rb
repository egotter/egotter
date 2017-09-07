class SettingsController < ApplicationController

  before_action only: %i(index) do
    push_referer
    create_search_log
  end

  def index
    return redirect_to root_path unless user_signed_in?
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
    render json: current_user.notification_setting.attributes.slice('email', 'dm', 'news', 'search'), status: 200
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{params.inspect}"
    head :internal_server_error
  end
end
