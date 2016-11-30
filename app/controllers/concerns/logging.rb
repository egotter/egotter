require 'digest/md5'
require 'active_support/concern'

module Concerns::Logging
  extend ActiveSupport::Concern

  included do

  end

  def create_search_log(options = {})
    uid, screen_name = find_uid_and_screen_name
    referral = find_referral(pushed_referers)

    attrs = {
      session_id:  fingerprint,
      user_id:     current_user_id,
      uid:         uid,
      screen_name: screen_name,
      action:      action_name,
      ego_surfing: user_signed_in? && current_user.uid.to_i == uid.to_i,
      method:      request.method,
      device_type: request.device_type,
      os:          request.os,
      browser:     request.browser,
      user_agent:  truncated_user_agent,
      referer:     truncated_referer,
      referral:    referral,
      channel:     find_channel(referral),
      first_time:  false,
      landing:     false,
      medium:      params[:medium] ? params[:medium] : '',
      created_at:  Time.zone.now
    }
    attrs.update(options) if options.any?
    CreateSearchLogWorker.perform_async(attrs)

    if via_notification?
      UpdateNotificationMessageWorker.perform_async(token: params[:token], read_at: attrs[:created_at], medium: attrs[:medium])
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{action_name}"
    logger.info e.backtrace.take(10).join("\n")
    Rollbar.warn(e)
  end

  def create_sign_in_log(user_id, context, via, follow)
    referral = find_referral(pushed_referers)

    attrs = {
      session_id:  fingerprint,
      user_id:     user_id,
      context:     context,
      follow:      follow,
      via:         via,
      device_type: request.device_type,
      os:          request.os,
      browser:     request.browser,
      user_agent:  truncated_user_agent,
      referer:     truncated_referer,
      referral:    referral,
      channel:     find_channel(referral),
      created_at:  Time.zone.now
    }
    CreateSignInLogWorker.perform_async(attrs)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{action_name}"
    logger.info e.backtrace.take(10).join("\n")
    Rollbar.warn(e)
  end

  def create_modal_open_log(via)
    referral = find_referral(pushed_referers)

    attrs = {
      session_id:  fingerprint,
      user_id:     current_user_id,
      via:         via,
      device_type: request.device_type,
      os:          request.os,
      browser:     request.browser,
      user_agent:  truncated_user_agent,
      referer:     truncated_referer,
      referral:    referral,
      channel:     find_channel(referral),
      created_at:  Time.zone.now
    }
    CreateModalOpenLogWorker.perform_async(attrs)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{action_name}"
    logger.info e.backtrace.take(10).join("\n")
    Rollbar.warn(e)
  end

  def create_page_cache_log(context)
    referral = find_referral(pushed_referers)

    attrs = {
      session_id:  fingerprint,
      user_id:     current_user_id,
      context:     context,
      device_type: request.device_type,
      os:          request.os,
      browser:     request.browser,
      user_agent:  truncated_user_agent,
      referer:     truncated_referer,
      referral:    referral,
      channel:     find_channel(referral),
      created_at:  Time.zone.now
    }
    CreatePageCacheLogWorker.perform_async(attrs)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{action_name}"
    logger.info e.backtrace.take(10).join("\n")
    Rollbar.warn(e)
  end

  def push_referer
    referer = truncated_referer
    if referer.present? && !referer.start_with?('https://egotter.com')
      Util::RefererList.new(Redis.client).push(fingerprint, referer)
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{action_name}"
    logger.info e.backtrace.take(10).join("\n")
    Rollbar.warn(e)
  end

  def pushed_referers
    Util::RefererList.new(Redis.client).to_a(fingerprint)
  end

  private

  def find_uid_and_screen_name
    if instance_variable_defined?(:@tu) && !@tu.nil? # create
      uid = @tu.uid
      screen_name = @tu.screen_name
    elsif instance_variable_defined?(:@searched_tw_user) && !@searched_tw_user.nil?
      uid = @searched_tw_user.uid
      screen_name = @searched_tw_user.screen_name
    elsif instance_variable_defined?(:@searched_tw_users) && !@searched_tw_users[0].nil?
      uid = @searched_tw_users[0].uid
      screen_name = @searched_tw_users[0].screen_name
    else
      uid = ::TwitterUser.new(uid: params[:uid]).valid_uid? ? params[:uid].to_i : -1
      if tu = fetch_twitter_user_from_cache(uid) # waiting
        uid = tu.uid
        screen_name = tu.screen_name
      else
        if uid != -1 && ::TwitterUser.exists?(uid: uid)
          screen_name = ::TwitterUser.latest(uid).screen_name
        else
          uid = screen_name = -1
        end
      end
    end

    [uid, screen_name]
  end

  def via_dm?
    params[:token].present? && %i(crawler UNKNOWN).exclude?(request.device_type) && params[:medium] == 'dm'
  end

  def via_onesignal?
    params[:token].present? && %i(crawler UNKNOWN).exclude?(request.device_type) && params[:medium] == 'onesignal'
  end

  def via_notification?
    via_dm? || via_onesignal?
  end

  def via_prompt_report?
    params[:token].present? && %i(crawler UNKNOWN).exclude?(request.device_type) && params[:type] == 'prompt_report'
  end

  def find_referral(referers)
    url = referers.find do |referer|
      referer.present? && referer.match(URI.regexp) && !URI.parse(referer).host.include?('egotter')
    end
    url.blank? ? '' : URI.parse(url).host
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    Rollbar.warn(e)
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
    Rollbar.warn(e)
    ''
  end

  def fingerprint
    if request.device_type == :crawler
      return -1
    end

    if session[:fingerprint].nil? || session[:fingerprint].to_s == '-1'
      session[:fingerprint] = session.id.nil? ? '-1' : session.id
    end

    if session[:fingerprint] == '-1'
      digest = Digest::MD5.hexdigest("#{Time.zone.now.to_i + rand(1000)}")
      session[:fingerprint] = "digest-#{digest}"
    end

    session[:fingerprint]
  end

  def truncated_user_agent
    request.user_agent.nil? ? '' : view_context.truncate(request.user_agent, length: 180, escape: false)
  end

  def truncated_referer
    request.referer.nil? ? '' : view_context.truncate(request.referer, length: 180, escape: false)
  end
end
