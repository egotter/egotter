require 'digest/md5'
require 'active_support/concern'

module Logging
  extend ActiveSupport::Concern
  include SessionsConcern
  include ReportsHelper

  included do

  end

  def access_log_disabled
    @access_log_disabled
  end

  def access_log_disabled=(flag)
    @access_log_disabled = flag
  end

  def create_access_log?
    !access_log_disabled && !apache_bench? && (response.successful? || response.redirection?)
  end

  def apache_bench?
    request.user_agent == 'ApacheBench/2.3' && request.ip == '127.0.0.1'
  end

  def create_access_log(options = {})
    return create_crawler_log if from_crawler?

    uid, screen_name = find_uid_and_screen_name
    save_params = request.query_parameters.dup.merge(request.request_parameters).except(:locale, :utf8, :authenticity_token)

    attrs = {
      session_id:  egotter_visit_id,
      user_id:     current_user_id,
      uid:         uid,
      screen_name: screen_name,
      controller:  controller_name,
      action:      action_name,
      method:      request.method,
      path:        request.path.to_s.truncate(180),
      params:      save_params.empty? ? '' : save_params.to_json.truncate(180),
      status:      response.status,
      via:         params[:via] ? params[:via].to_s.truncate(180) : '',
      device_type: request.device_type,
      os:          request.os,
      browser:     request.browser,
      ip:          request.ip,
      user_agent:  ensure_utf8(request.user_agent.to_s.truncate(180)),
      referer:     request.referer.to_s.truncate(1000),
      created_at:  Time.zone.now
    }

    CreateSearchLogWorker.perform_async(attrs)
    CreateAccessDayWorker.perform_async(current_user.id) if user_signed_in?

    if via_dm?
      job_options = {token: params[:token], read_at: attrs[:created_at]}
      case
        when via_periodic_report? then UpdatePeriodicReportWorker.perform_async(job_options)
        when via_search_report?   then UpdateSearchReportWorker.perform_async(job_options)
        when via_block_report?    then UpdateBlockReportWorker.perform_async(job_options)
        when via_welcome_message? then UpdateWelcomeMessageWorker.perform_async(job_options)
      end
    end
  rescue Encoding::UndefinedConversionError => e
    logger.warn "#{self.class}##{__method__}: #{e.inspect} params=#{params.inspect} user_agent=#{request.user_agent}"
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.inspect} params=#{params.inspect} user_agent=#{request.user_agent}"
  end

  def create_error_log(location, message, ex = nil)
    uid = @twitter_user&.uid || params[:uid] || -1
    screen_name = @twitter_user&.screen_name || params[:screen_name] || ''

    message = ActionController::Base.helpers.strip_tags(message)
    message += ex.message if ex

    save_params = request.query_parameters.dup.merge(request.request_parameters).except(:locale, :utf8, :authenticity_token)

    if from_crawler? && request.device_type != 'crawler'
      device_type = 'crawler'
    else
      device_type = request.device_type
    end

    attrs = {
        session_id:  egotter_visit_id,
        user_id:     current_user_id,
        uid:         uid,
        screen_name: screen_name,
        location:    location.to_s.truncate(180),
        message:     message.gsub("\n", ' ').truncate(180),
        controller:  controller_name,
        action:      action_name,
        xhr:         !!request.xhr?,
        method:      request.method,
        path:        request.path.to_s.truncate(180),
        params:      save_params.empty? ? '' : save_params.to_json.truncate(180),
        status:      performed? ? response.status : 500,
        via:         params[:via] ? params[:via] : '',
        device_type: device_type,
        os:          request.os,
        browser:     request.browser,
        ip:          request.ip,
        user_agent:  ensure_utf8(request.user_agent.to_s.truncate(180)),
        referer:     request.referer.to_s.truncate(180),
        created_at:  Time.zone.now
    }

    CreateSearchErrorLogWorker.perform_async(attrs)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.inspect} params=#{params.inspect} user_agent=#{request.user_agent}"
  end

  def create_crawler_log
    save_params = request.query_parameters.dup.merge(request.request_parameters).except(:locale, :utf8, :authenticity_token)

    attrs = {
      controller:  controller_name,
      action:      action_name,
      device_type: request.device_type,
      os:          request.os,
      browser:     request.browser,
      ip:          request.ip,
      method:      request.method,
      path:        request.path.to_s.truncate(180),
      params:      save_params.empty? ? '' : save_params.to_json.truncate(180),
      status:      response.status,
      user_agent:  request.user_agent.to_s.truncate(180),
    }
    CreateCrawlerLogWorker.perform_async(attrs)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.inspect} params=#{params.inspect} user_agent=#{request.user_agent}"
  end

  def track_event(name, properties = nil)
    ahoy.track(name, properties)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.inspect} name=#{name} properties=#{properties.inspect}"
  end

  def track_sign_in_event(context:, via:)
    name = context == :create ? 'Sign up' : 'Sign in'
    properties = via.blank? ? nil : {via: via}
    ahoy.track(name, properties)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.inspect} action_name=#{action_name}"
  end

  def track_order_activity(prop = {})
    event_params = request.query_parameters.dup.merge(request.request_parameters).except(:data, :locale, :utf8, :authenticity_token)
    properties = {path: request.path, params: event_params}.merge(prop)
    track_event('Order activity', properties)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.inspect} prop=#{prop}"
  end

  private

  def find_uid_and_screen_name
    if @twitter_user
      uid = @twitter_user.uid
      screen_name = @twitter_user.screen_name
    elsif @screen_name
      uid = -1
      screen_name = @screen_name
    else
      uid = screen_name = -1
    end

    [uid, screen_name]
  end

  def ensure_utf8(str)
    str.encode("UTF-8", "binary", invalid: :replace, undef: :replace, replace: '')
  end
end
