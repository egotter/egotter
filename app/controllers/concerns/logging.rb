require 'digest/md5'

module Logging
  extend ActiveSupport::Concern

  included do

  end

  def create_search_log(options = {})
    uid, screen_name = find_uid_and_screen_name
    user_id = current_user_id

    attrs = {
      session_id:  fingerprint,
      user_id:     user_id,
      uid:         uid,
      screen_name: screen_name,
      action:      action_name,
      ego_surfing: user_id != -1 && user_id.to_i == uid.to_i,
      method:      request.method,
      device_type: request.device_type,
      os:          request.os,
      browser:     request.browser,
      user_agent:  truncated_user_agent,
      referer:     truncated_referer,
      channel:     find_channel,
      created_at:  Time.zone.now
    }
    attrs.update(options) if options.any?
    CreateSearchLogWorker.perform_async(attrs)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{action_name} #{e.class} #{e.message}"
    logger.info e.backtrace.slice(0, 10).join("\n")
  end

  def create_sign_in_log(user_id, context, via)
    attrs = {
      session_id:  fingerprint,
      user_id:     user_id,
      context:     context,
      via:         via,
      device_type: request.device_type,
      os:          request.os,
      browser:     request.browser,
      user_agent:  truncated_user_agent,
      referer:     truncated_referer,
      channel:     find_channel,
      created_at:  Time.zone.now
    }
    CreateSignInLogWorker.perform_async(attrs)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{action_name} #{e.class} #{e.message}"
    logger.info e.backtrace.slice(0, 10).join("\n")
  end

  def create_modal_open_log(name)
    attrs = {
      session_id:  fingerprint,
      user_id:     current_user_id,
      name:        name,
      device_type: request.device_type,
      os:          request.os,
      browser:     request.browser,
      user_agent:  truncated_user_agent,
      referer:     truncated_referer,
      channel:     find_channel,
      created_at:  Time.zone.now
    }
    CreateModalOpenLogWorker.perform_async(attrs)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{action_name} #{e.class} #{e.message}"
    logger.info e.backtrace.slice(0, 10).join("\n")
  end

  def push_referer
    Util::RefererList.new(Redis.client).push(fingerprint, request.referer.nil? ? '' : request.referer)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{action_name} #{e.class} #{e.message}"
    logger.info e.backtrace.slice(0, 10).join("\n")
  end

  private

  def find_uid_and_screen_name
    if instance_variable_defined?(:@tu) && !@tu.nil? # create
      uid = @tu.uid
      screen_name = @tu.screen_name
    else
      uid = TwitterUser.new(uid: params[:id]).valid_uid? ? params[:id].to_i : -1
      if tu = fetch_twitter_user_from_cache(uid) # waiting
        uid = tu.uid
        screen_name = tu.screen_name
      else
        if uid != -1 && TwitterUser.exists?(uid: uid)
          screen_name = TwitterUser.latest(uid).screen_name
        else
          uid = screen_name = -1
        end
      end
    end

    [uid, screen_name]
  end

  def find_channel
    channel_url = Util::RefererList.new(Redis.client).to_a(fingerprint).find do |referer|
      !referer.nil? && referer != '' && !URI.parse(referer).host.include?('egotter')
    end
    channel_url.blank? ? '' : URI.parse(channel_url).host
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
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