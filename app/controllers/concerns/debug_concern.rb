require 'active_support/concern'

module Concerns::DebugConcern
  extend ActiveSupport::Concern

  def request_details
    request_details_json.values.join(' ')
  end

  def request_details_json
    {
        user_id: current_user_id,
        method: request.method,
        device_type: request.device_type,
        browser: request.browser,
        xhr: request.xhr?,
        full_path: request.fullpath,
        referer: request.referer,
        params: request.query_parameters,
        '@twitter_user': @twitter_user&.attributes,
        '@search_request_start_time': @search_request_start_time,
        '@search_request_benchmark': @search_request_benchmark,
    }
  end
end
