require 'active_support/concern'

module TwitterErrorHandler
  extend ActiveSupport::Concern
  include DebugConcern

  included do
    rescue_from Twitter::Error::BadRequest, with: :handle_twitter_error_unauthorized
    rescue_from Twitter::Error::Unauthorized, with: :handle_twitter_error_unauthorized
  end

  private

  def handle_twitter_error_unauthorized(ex)
    Airbag.warn "#{__method__} #{ex.class} #{ex.message.truncate(100)} #{request_details.inspect}"
    Airbag.info ex.backtrace.join("\n")

    if request.xhr?
      head :internal_server_error
    else
      redirect_to error_pages_twitter_error_path(via: current_via)
    end
  end
end
