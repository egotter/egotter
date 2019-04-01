require 'active_support/concern'

module Concerns::DebugConcern
  extend ActiveSupport::Concern

  def request_details
    "#{request.method} #{current_user_id} #{request.device_type} #{request.browser} #{request.xhr?} #{request.fullpath} #{request.referer} #{params.inspect}"
  end
end
