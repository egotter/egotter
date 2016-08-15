require 'digest/md5'

module Logging
  extend ActiveSupport::Concern

  included do

  end

  def create_search_log(options = {})
    user_id = current_user_id

    if instance_variable_defined?(:@tu) # create
      uid = @tu.uid
      screen_name = @tu.screen_name
    else
      uid = TwitterUser.new(uid: params[:id]).valid_uid? ? params[:id].to_i : -1
      if tu = fetch_twitter_user_from_cache(uid, user_id) # waiting
        uid = tu.uid
        screen_name = tu.screen_name
      else
        if TwitterUser.exists?(uid: uid, user_id: user_id)
          screen_name = TwitterUser.latest(uid, user_id).screen_name
        else
          uid = screen_name = -1
        end
      end
    end

    attrs = {
      session_id:  fingerprint,
      user_id:     current_user_id,
      uid:         uid,
      screen_name: screen_name,
      action:      action_name,
      ego_surfing: ego_surfing?(uid),
      method:      request.method,
      device_type: request.device_type,
      os:          request.os,
      browser:     request.browser,
      user_agent:  truncated_user_agent,
      referer:     truncated_referer,
      created_at:  Time.zone.now
    }
    attrs.update(options) if options.any?
    CreateSearchLogWorker.perform_async(attrs)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{action_name} #{e.class} #{e.message}"
  end

  def create_sign_in_log(user_id, context)
    attrs = {
      session_id:  fingerprint,
      user_id:     user_id,
      context:     context,
      device_type: request.device_type,
      os:          request.os,
      browser:     request.browser,
      user_agent:  truncated_user_agent,
      referer:     truncated_referer,
      created_at:  Time.zone.now
    }
    CreateSignInLogWorker.perform_async(attrs)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{action_name} #{e.class} #{e.message}"
  end

  def push_referer
    Util::RefererList.new(Redis.client).push(fingerprint, request.referer.nil? ? '' : request.referer)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{action_name} #{e.class} #{e.message}"
  end

  private

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

  def ego_surfing?(uid)
    user_signed_in? && current_user.uid.to_i == uid.to_i
  end

  def truncated_user_agent
    request.user_agent.nil? ? '' : view_context.truncate(request.user_agent, length: 180, escape: false)
  end

  def truncated_referer
    request.referer.nil? ? '' : view_context.truncate(request.referer, length: 180, escape: false)
  end
end