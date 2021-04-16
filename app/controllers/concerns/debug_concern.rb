require 'active_support/concern'

module DebugConcern
  extend ActiveSupport::Concern

  def request_details
    {
        user_id: current_user_id,
        method: request.method,
        device_type: request.device_type,
        browser: request.browser,
        xhr: request.xhr?,
        full_path: request.fullpath,
        referer: request.referer,
        user_agent: request.user_agent,
        params: request.query_parameters,
        twitter_user_id: @twitter_user&.id,
    }
  end
end
