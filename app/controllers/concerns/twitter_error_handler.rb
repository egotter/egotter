require 'active_support/concern'

module Concerns::TwitterErrorHandler
  extend ActiveSupport::Concern
  include Concerns::AlertMessagesConcern
  include Concerns::DebugConcern

  included do
    rescue_from Twitter::Error::BadRequest, with: :handle_twitter_error_unauthorized
    rescue_from Twitter::Error::Unauthorized, with: :handle_twitter_error_unauthorized
  end

  private

  def handle_twitter_error_unauthorized(ex)
    truncated_message = ex.message.truncate(100)

    logger.warn "#{__method__} #{ex.class} #{truncated_message} #{request_details}"
    logger.info ex.backtrace.join("\n")

    if request.xhr?
      render json: {error: truncated_message}, status: :internal_server_error
    else
      self.sidebar_disabled = true
      if user_signed_in?
        flash.now[:alert] = signed_in_user_not_authorized_message
      else
        flash.now[:alert] = unknown_alert_message(ex)
      end
      render template: 'home/new', formats: %i(html), status: :internal_server_error
    end
  end
end
