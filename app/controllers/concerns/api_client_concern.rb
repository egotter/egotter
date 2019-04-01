require 'active_support/concern'

module Concerns::ApiClientConcern
  extend ActiveSupport::Concern

  def request_context_client
    @request_context_client ||= (user_signed_in? ? current_user.api_client : Bot.api_client)
  end
end
