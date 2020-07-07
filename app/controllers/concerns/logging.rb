require 'digest/md5'
require 'active_support/concern'

module Concerns::Logging
  extend ActiveSupport::Concern
  include Concerns::SessionsConcern
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
      referer:     request.referer.to_s.truncate(180),
      created_at:  Time.zone.now
    }

    CreateSearchLogWorker.perform_async(attrs)
    CreateAccessDayWorker.perform_async(current_user.id) if user_signed_in?

    if via_dm?
      job_options = {token: params[:token], read_at: attrs[:created_at]}
      case
        when via_periodic_report? then UpdatePeriodicReportWorker.perform_async(job_options)
        when via_search_report?   then UpdateSearchReportWorker.perform_async(job_options)
        when via_news_report?     then UpdateNewsReportWorker.perform_async(job_options)
        when via_welcome_message? then UpdateWelcomeMessageWorker.perform_async(job_options)
      end
    end
  rescue Encoding::UndefinedConversionError => e
    logger.warn "#{self.class}##{__method__}: #{e.inspect} params=#{params.inspect} user_agent=#{request.user_agent}"
    notify_airbrake(e)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.inspect} params=#{params.inspect} user_agent=#{request.user_agent}"
    notify_airbrake(e)
  end

  def create_error_log(location, message, ex = nil)
    uid = @twitter_user&.uid || params[:uid] || -1
    screen_name = @twitter_user&.screen_name || params[:screen_name] || ''

    message = ActionController::Base.helpers.strip_tags(message)
    message += ex.message if ex

    save_params = request.query_parameters.dup.merge(request.request_parameters).except(:locale, :utf8, :authenticity_token)

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
        device_type: request.device_type,
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
    notify_airbrake(e)
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
    notify_airbrake(e)
  end

  def create_sign_in_log(user, context:, via:, follow:, tweet:, referer:)
    attrs = {
      session_id:  egotter_visit_id,
      user_id:     user.id,
      uid:         user.uid,
      screen_name: user.screen_name,
      context:     context,
      follow:      follow,
      tweet:       tweet,
      via:         via,
      device_type: request.device_type,
      os:          request.os,
      browser:     request.browser,
      ip:          request.ip,
      user_agent:  request.user_agent.to_s.truncate(180),
      referer:     referer.to_s.truncate(180),
      created_at:  Time.zone.now
    }
    CreateSignInLogWorker.perform_async(attrs)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.inspect} action_name=#{action_name}"
    notify_airbrake(e)
  end

  def track_sign_in_event(context:, via:)
    event_name = context == :create ? 'Sign up' : 'Sign in'
    event_params = {via: via}.reject { |_, v| v.blank? }
    event_params = nil if event_params.blank?
    ahoy.track(event_name, event_params)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.inspect} action_name=#{action_name}"
    notify_airbrake(e)
  end

  private

  def find_uid_and_screen_name
    if instance_variable_defined?(:@tu) && !@tu.nil? # create
      uid = @tu.uid
      screen_name = @tu.screen_name
    elsif instance_variable_defined?(:@twitter_user) && !@twitter_user.nil?
      uid = @twitter_user.uid
      screen_name = @twitter_user.screen_name
    else
      uid = valid_uid?(params[:uid], only_validation: true) ? params[:uid].to_i : -1
      if uid != -1 && TwitterUser.exists?(uid: uid)
        screen_name = TwitterUser.latest_by(uid: uid).screen_name
      else
        uid = screen_name = -1
      end
    end

    [uid, screen_name]
  end

  def find_referral(referers)
    url = referers.find do |referer|
      referer.present? && referer.match?(URI.regexp) && !URI.parse(referer).host.include?('egotter')
    end
    url.blank? ? '' : URI.parse(url).host
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    ''
  end

  def find_channel(referral)
    twitter = ->r{ %w(t.co twitter.com api.twitter.com mobile.twitter.com tweetdeck.twitter.com).include? r }
    naver = ->r{ %w(matome.naver.jp).include? r }
    google = ->r{ r.start_with? 'www.google' }
    yahoo = ->r{ %w(search.yahoo.co.jp).include? r }
    chiebukuro = ->r{ %w(m.chiebukuro.yahoo.co.jp detail.chiebukuro.yahoo.co.jp).include? r }
    livedoor = ->r{ %w(news.livedoor.com).include? r }

    case referral
      when nil, ''     then ''
      when twitter     then 'twitter'
      when naver       then 'naver'
      when google      then 'google'
      when yahoo       then 'yahoo'
      when chiebukuro  then 'chiebukuro'
      when livedoor    then 'livedoor'
      else 'others'
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    notify_airbrake(e)
    ''
  end

  def ensure_utf8(str)
    str.encode("UTF-8", "binary", invalid: :replace, undef: :replace, replace: '')
  end
end
