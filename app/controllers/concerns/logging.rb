require 'digest/md5'
require 'active_support/concern'

module Logging
  extend ActiveSupport::Concern
  include SessionsConcern
  include ReportsHelper

  included do

  end

  def create_access_log?
    !apache_bench? && (response.successful? || response.redirection?)
  end

  def apache_bench?
    request.user_agent == 'ApacheBench/2.3' && request.ip == '127.0.0.1'
  end

  def create_access_log(options = {})
    return create_webhook_log if twitter_webhook?
    return create_crawler_log if from_crawler?

    uid, screen_name = find_uid_and_screen_name
    save_params = concatenated_params

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
      via:         safe_via,
      device_type: request.device_type,
      os:          request.os,
      browser:     request.browser,
      ip:          request.ip,
      user_agent:  safe_user_agent,
      referer:     safe_referer,
      created_at:  Time.zone.now
    }

    CreateSearchLogWorker.perform_async(attrs)

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
    # This error occurs when multibyte characters are passed to JSON.generate to enqueue the job.
    # Some crawlers use multibyte characters in the User-Agent even though only ASCII characters can be used.
    # To avoid this error use #inspect instead of #to_s.
    # Reproduce: str = "あ".force_encoding('ASCII-8BIT'); JSON.generate(str)
    Airbag.exception e, path: request.path, user_agent: request.user_agent.inspect
  rescue => e
    Airbag.exception e, path: request.path, user_agent: request.user_agent.inspect
  end

  def create_access_day
    CreateAccessDayWorker.perform_async(current_user.id) if user_signed_in?
  rescue => e
    Airbag.exception e, user_id: current_user&.id
  end

  def create_error_log(location, message, ex = nil)
    uid = @twitter_user&.uid || params[:uid] || -1
    screen_name = @twitter_user&.screen_name || params[:screen_name] || ''

    message = ActionController::Base.helpers.strip_tags(message)
    message += ex.message if ex

    save_params = concatenated_params

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
        via:         safe_via,
        device_type: device_type,
        os:          request.os,
        browser:     request.browser,
        ip:          request.ip,
        user_agent:  safe_user_agent,
        referer:     safe_referer,
        created_at:  Time.zone.now
    }

    CreateSearchErrorLogWorker.perform_async(attrs)
  rescue => e
    Airbag.exception e, path: request.path, user_agent: request.user_agent.inspect
  end

  def create_crawler_log
    save_params = concatenated_params

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
      user_agent:  safe_user_agent,
    }
    CreateCrawlerLogWorker.perform_async(attrs)
  rescue => e
    Airbag.exception e, path: request.path, user_agent: request.user_agent.inspect
  end

  def create_webhook_log
    save_params = concatenated_params
    if twitter_webhook?
      save_params['webhook'] = '[REMOVED]' if save_params.has_key?('webhook')
      save_params['apps'] = '[REMOVED]' if save_params.has_key?('apps')
      save_params['users'] = '[REMOVED]' if save_params.has_key?('users')
      if save_params.has_key?('direct_message_events')
        save_params['direct_message_events'].each do |event|
          if (message_data = event.dig('message_create', 'message_data'))
            message_data['entities'] = '[REMOVED]'
          end
        end
      end rescue nil
    end

    attrs = {
        controller:  controller_name,
        action:      action_name,
        path:        request.path.to_s.truncate(180),
        params:      save_params.empty? ? nil : save_params,
        ip:          request.ip,
        method:      request.method,
        status:      response.status,
        user_agent:  safe_user_agent,
    }

    CreateWebhookLogWorker.perform_async(attrs)
  rescue => e
    Airbag.exception e, path: request.path, user_agent: request.user_agent.inspect
  end

  def create_stripe_webhook_log(idempotency_key, event_id, event_type, event_data)
    attrs = {
        controller:      controller_name,
        action:          action_name,
        path:            request.path.to_s.truncate(180),
        idempotency_key: idempotency_key,
        event_id:        event_id,
        event_type:      event_type,
        event_data:      event_data,
        ip:              request.ip,
        method:          request.method,
        status:          response.status,
        user_agent:      safe_user_agent,
    }

    CreateStripeWebhookLogWorker.perform_async(attrs)
  rescue => e
    Airbag.exception e, idempotency_key: idempotency_key, event_id: event_id, event_type: event_type, event_data: event_data
  end

  def track_page_order_activity(options = {})
    properties = {
        path: request.path,
        via: safe_via
    }.merge(options).delete_if { |_, v| v.blank? }.presence
    ahoy.track('Order activity', properties)
  rescue => e
    Airbag.exception e, controller: controller_name, action: action_name, options: options
  end

  def track_webhook_order_activity
    properties = {path: request.path, id: params[:id], type: params[:type]}
    ahoy.track('Order activity', properties)
  rescue => e
    Airbag.exception e, controller: controller_name, action: action_name
  end

  # TODO Remove later
  def track_order_activity(prop = {})
    event_params = request.query_parameters.merge(request.request_parameters).except(:data, :locale, :utf8, :authenticity_token)
    properties = {path: request.path, params: event_params}.merge(prop)
    ahoy.track('Order activity', properties)
  rescue => e
    Airbag.exception e, prop: prop
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

  def concatenated_params
    request.query_parameters.merge(request.request_parameters).except(:locale, :utf8, :authenticity_token)
  end

  def safe_via
    params[:via].to_s.truncate(180)
  end

  def safe_user_agent
    ensure_utf8(request.user_agent).to_s.truncate(180)
  end

  def safe_referer
    params[:referer].to_s.truncate(180)
  end

  def ensure_utf8(str)
    str.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '') if str
  end
end
