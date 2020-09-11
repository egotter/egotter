require 'active_support/concern'

module ApiClientConcern
  extend ActiveSupport::Concern

  def request_context_client
    @request_context_client ||= (user_signed_in? ? current_user.api_client : Bot.api_client)
  end
end
