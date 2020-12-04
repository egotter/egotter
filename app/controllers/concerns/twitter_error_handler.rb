require 'active_support/concern'

module TwitterErrorHandler
  extend ActiveSupport::Concern
  include AlertMessagesConcern
  include DebugConcern

  included do
    rescue_from Twitter::Error::BadRequest, with: :handle_twitter_error_unauthorized
    rescue_from Twitter::Error::Unauthorized, with: :handle_twitter_error_unauthorized
  end

  private

  def handle_twitter_error_unauthorized(ex)
    logger.warn "#{__method__} #{ex.class} #{ex.message.truncate(100)} #{request_details}"
    logger.info ex.backtrace.join("\n")

    if request.xhr?
      render json: {message: nil}, status: :internal_server_error
    else
      self.sidebar_disabled = true
      if user_signed_in?
        flash.now[:alert] = signed_in_user_not_authorized_message
      else
        flash.now[:alert] = unknown_alert_message(ex)
      end
      @has_error = true
      render template: 'home/new', formats: %i(html), status: :internal_server_error
    end
  end
end
