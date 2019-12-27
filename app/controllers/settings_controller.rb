class SettingsController < ApplicationController
  include Concerns::JobQueueingConcern

  before_action :require_login!
  before_action :create_search_log

  def index
    enqueue_update_authorized
    enqueue_update_egotter_friendship

    @latest_prompt_report = current_user.prompt_reports.first
    @latest_prompt_report_log = CreatePromptReportLog.latest_by(user_id: current_user.id)
    @reset_egotter_request = current_user.reset_egotter_requests.not_finished.where(created_at: 12.hours.ago..Time.zone.now).exists?
    @reset_cache_request = current_user.reset_cache_requests.not_finished.where(created_at: 12.hours.ago..Time.zone.now).exists?
  end

  def update
    key, value = pick_sent_value
    current_user.notification_setting.update!(key => value) if key
    render json: current_user.notification_setting.attributes.slice('email', 'dm', 'news', 'search', 'report_if_changed')
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
    @users = TwitterDB::User.where(uid: @requests.map(&:uid)).index_by(&:uid)
  end

  def unfollow_requests
    @requests = current_user.unfollow_requests.limit(20)
    @users = TwitterDB::User.where(uid: @requests.map(&:uid)).index_by(&:uid)
  end

  def create_prompt_report_requests
    @requests = current_user.create_prompt_report_requests.includes(:logs).limit(20)
  end

  def create_test_report_requests
    @requests = current_user.create_test_report_requests.includes(:logs).limit(20)
  end

  def twitter_users
    @twitter_users = TwitterUser.where(uid: current_user.uid).order(created_at: :desc).limit(20)
  end

  private

  def pick_sent_value
    %i(email dm news search report_if_changed).each do |name|
      if params[name]
        return [name, params[name] == 'true']
      end
    end
    [nil, nil]
  end
end
