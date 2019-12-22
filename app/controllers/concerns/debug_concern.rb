require 'active_support/concern'

module Concerns::DebugConcern
  extend ActiveSupport::Concern

  def request_details
    "#{request.method} #{current_user_id} #{request.device_type} #{request.browser} #{request.xhr?} #{request.fullpath} #{request.referer} #{request.query_parameters}"
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
    }
  end
end
