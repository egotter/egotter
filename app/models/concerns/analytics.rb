require 'active_support/concern'

module Concerns::Analytics
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  def source
    log = search_logs.select(:path, :referer).first
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
