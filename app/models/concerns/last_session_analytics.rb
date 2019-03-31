require 'active_support/concern'

module Concerns::LastSessionAnalytics
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end


  def last_session_search_logs
    condition =
        if respond_to?(:session_id)
          {session_id: session_id}
        elsif self.class == User
          {user_id: id}
        end

    SearchLog.where(created_at: last_session_duration).
        where(condition).
        order(created_at: :asc)
  end

  def last_session_device_type
    last_session_search_logs.first&.device_type
  end

  def last_session_via
    last_session_search_logs.first&.via
  end

  def last_session_user_found?
    user_id = last_session_search_logs.first&.user_id
    user_id && user_id != -1
  end

  def last_session_source
    log = last_session_search_logs.select(:path, :referer).first
    return 'log not found' unless log

    if log.referer.blank?
      path_uri = URI.parse(log.path)
      path_query = URI::decode_www_form(path_uri.query.to_s).to_h

      result =
          if path_uri.path.start_with?('/timelines/') && path_query['medium'] == 'dm'
            "dm(#{path_query['type']}, direct)"
          else
            path_name = path_uri.path == '/' ? '/' : path_uri.path.split('/')[1]
            "blank referer(#{path_name})"
          end

      return result
    end

    uri = URI.parse(log.referer)
    query = URI::decode_www_form(uri.query.to_s).to_h

    if uri.host == 't.co'
      path_uri = URI.parse(log.path)
      path_query = URI::decode_www_form(path_uri.query.to_s).to_h

      if path_uri.path.start_with?('/timelines/') && path_query['medium'] == 'dm'
        "dm(#{path_query['type']})"
      else
        uri.host
      end
    else
      uri.host.remove(/\.cdn\.ampproject\.org$/)
    end
  end
end
