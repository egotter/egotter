class SettingsController < ApplicationController
  include Concerns::JobQueueingConcern

  before_action :require_login!
  before_action :create_search_log

  def index
    enqueue_update_authorized
    enqueue_update_egotter_friendship

    @latest_prompt_report = current_user.prompt_reports.first
    @latest_prompt_report_log = CreatePromptReportLog.latest_by(user_id: current_user.id)
    @update_histories = UpdateHistories.new(current_user.uid)
    @reset_egotter_request = current_user.reset_egotter_requests.not_finished.exists?
    @reset_cache_request = current_user.reset_cache_requests.not_finished.exists?
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

  def update_report_interval
    current_user.notification_setting.update!(report_interval: params[:report_interval])
    render json: {report_interval: current_user.notification_setting.report_interval}
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{params.inspect}"
    head :internal_server_error
  end

  def follow_requests
    @requests = current_user.follow_requests.limit(20)
  end

  def unfollow_requests
    @requests = current_user.unfollow_requests.limit(20)
  end

  def create_prompt_report_requests
    @requests = current_user.create_prompt_report_requests.includes(:logs).limit(20)
  end

  def create_test_report_requests
    @requests = current_user.create_test_report_requests.includes(:logs).limit(20)
  end
end
