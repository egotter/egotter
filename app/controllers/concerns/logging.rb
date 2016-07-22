require "digest/md5"

module Logging
  extend ActiveSupport::Concern

  included do

  end

  def create_search_log
    uid = params.has_key?(:id) ? params[:id].match(/\A\d+\z/)[0].to_i : -1
    user_id = current_user_id
    if TwitterUser.exists?(uid: uid, user_id: user_id)
      screen_name = TwitterUser.latest(uid, user_id).screen_name
    else
      uid = screen_name = -1
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
      user_agent:  user_agent,
      referer:     referer,
      created_at:  Time.zone.now
    }
    CreateSearchLogWorker.perform_async(attrs)
  rescue => e
    logger.warn "#{self.class}##{__method__} #{action_name} #{e.class} #{e.message}"
  end

  def create_sign_in_log(user_id, context)
    attrs = {
      session_id:  fingerprint,
      user_id:     user_id,
      context:     context,
      device_type: request.device_type,
      os:          request.os,
      browser:     request.browser,
      user_agent:  user_agent,
      referer:     referer,
      created_at:  Time.zone.now
    }
    CreateSignInLogWorker.perform_async(attrs)
  rescue => e
    logger.warn "#{self.class}##{__method__} #{action_name} #{e.class} #{e.message}"
  end

  private

  def fingerprint
    if session[:fingerprint].nil? || session[:fingerprint].to_s == '-1'
      session[:fingerprint] = (session.id.nil? ? '-1' : session.id)
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

  def user_agent
    request.user_agent.nil? ? '' : view_context.truncate(request.user_agent, length: 180, escape: false)
  end

  def referer
    request.referer.nil? ? '' : view_context.truncate(request.referer, length: 180, escape: false)
  end
end