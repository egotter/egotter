require 'digest/md5'
require 'active_support/concern'

module Concerns::Logging
  extend ActiveSupport::Concern
  include Concerns::SessionsConcern
  include ReportsHelper

  included do

  end

  def create_search_log(options = {})
    if from_crawler?
      return create_crawler_log
    end

    uid, screen_name = find_uid_and_screen_name
    referral = find_referral(pushed_referers)

    attrs = {
      session_id:  fingerprint,
      user_id:     current_user_id,
      uid:         uid,
      screen_name: screen_name,
      controller:  controller_name,
      action:      action_name,
      cache_hit:   false,
      ego_surfing: user_signed_in? && current_user.uid == uid.to_i,
      method:      request.method,
      path:        request.original_fullpath.to_s.truncate(180),
      status:      200,
      via:         params[:via] ? params[:via] : '',
      device_type: request.device_type,
      os:          request.os,
      browser:     request.browser,
      user_agent:  ensure_utf8(request.user_agent.to_s.truncate(180)),
      referer:     request.referer.to_s.truncate(180),
      referral:    referral,
      channel:     find_channel(referral),
      medium:      params[:medium] ? params[:medium] : '',
      ab_test:     params[:ab_test] ? params[:ab_test] : '',
      created_at:  Time.zone.now
    }

    attrs.update(options) if options.any?
    CreateSearchLogWorker.perform_async(attrs)

    if via_dm?
      case
        when via_prompt_report?   then UpdatePromptReportWorker.perform_async(token: params[:token], read_at: attrs[:created_at])
        when via_search_report?   then UpdateSearchReportWorker.perform_async(token: params[:token], read_at: attrs[:created_at])
        when via_news_report?     then UpdateNewsReportWorker.perform_async(token: params[:token], read_at: attrs[:created_at])
        when via_welcome_message? then UpdateWelcomeMessageWorker.perform_async(token: params[:token], read_at: attrs[:created_at])
      end
    end
  rescue Encoding::UndefinedConversionError => e
    logger.warn "#{__method__}: #{e.class} #{e.message} #{params.inspect} #{request.user_agent}"
    logger.info e.backtrace.join("\n")
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message} #{params.inspect} #{request.user_agent}"
    logger.info e.backtrace.join("\n")
  end

  def create_search_error_log(location, message, ex = nil)
    uid = @twitter_user&.uid || params[:uid] || -1
    screen_name = @twitter_user&.screen_name || params[:screen_name] || ''

    message = ActionController::Base.helpers.strip_tags(message)
    message += ex.message if ex

    attrs = {
        session_id:  fingerprint,
        user_id:     current_user_id,
        uid:         uid,
        screen_name: screen_name,
        location:    location.to_s.truncate(180),
        message:     message.truncate(180),
        controller:  controller_name,
        action:      action_name,
        xhr:         !!request.xhr?,
        method:      request.method,
        path:        request.original_fullpath.to_s.truncate(180),
        status:      performed? ? response.status : 500,
        via:         params[:via] ? params[:via] : '',
        device_type: request.device_type,
        os:          request.os,
        browser:     request.browser,
        user_agent:  ensure_utf8(request.user_agent.to_s.truncate(180)),
        referer:     request.referer.to_s.truncate(180),
        created_at:  Time.zone.now
    }

    CreateSearchErrorLogWorker.perform_async(attrs)
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message} #{params.inspect} #{request.user_agent}"
    logger.info e.backtrace.join("\n")
  end

  def create_crawler_log
    attrs = {
      controller:  controller_name,
      action:      action_name,
      device_type: request.device_type,
      os:          request.os,
      browser:     request.browser,
      ip:          request.ip,
      method:      request.method,
      path:        request.original_fullpath.to_s.truncate(180),
      status:      200,
      user_agent:  request.user_agent.to_s.truncate(180),
    }
    CreateCrawlerLogWorker.perform_async(attrs)
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message} #{params.inspect} #{request.user_agent}"
    logger.info e.backtrace.join("\n")
  end

  def create_sign_in_log(user, context:, via:, follow:, tweet:, referer:, ab_test: '')
    referral = find_referral(pushed_referers)

    attrs = {
      session_id:  fingerprint,
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
      user_agent:  request.user_agent.to_s.truncate(180),
      referer:     referer.to_s.truncate(180),
      referral:    referral,
      channel:     find_channel(referral),
      ab_test:     ab_test,
      created_at:  Time.zone.now
    }
    CreateSignInLogWorker.perform_async(attrs)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{action_name}"
    logger.info e.backtrace.join("\n")
  end

  def push_referer
    referer = request.referer.to_s.truncate(180)
    if referer.present? && !referer.start_with?('https://egotter.com')
      Util::RefererList.new(Redis.client).push(fingerprint, referer)
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{action_name}"
    logger.info e.backtrace.join("\n")
  end

  def pushed_referers
    Util::RefererList.new(Redis.client).to_a(fingerprint)
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
    logger.info e.backtrace.join("\n")
    ''
  end

  def ensure_utf8(str)
    str.encode("UTF-8", "binary", invalid: :replace, undef: :replace, replace: '')
  end
end
