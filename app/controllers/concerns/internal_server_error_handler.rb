require 'active_support/concern'

module InternalServerErrorHandler
  extend ActiveSupport::Concern
  include AlertMessagesConcern
  include DebugConcern

  included do
    rescue_from StandardError, with: :handle_general_error
    rescue_from Rack::Timeout::RequestTimeoutException, with: :handle_request_timeout
    rescue_from ActionController::InvalidAuthenticityToken, with: :handle_csrf_error
  end

  private

  def handle_general_error(ex)
    handle_request_error(ex)
    create_error_log(__method__, 'internal_server_error', ex)

    if request.xhr?
      head :internal_server_error
    else
      render file: "#{Rails.root}/public/500.html", status: :internal_server_error, layout: false unless performed?
    end
  end

  def handle_request_timeout(ex)
    handle_request_error(ex)
    create_error_log(__method__, 'request_timeout', ex)

    if request.xhr?
      head :request_timeout
    else
      render file: "#{Rails.root}/public/408.html", status: :request_timeout, layout: false unless performed?
    end
  end

  def handle_csrf_error(ex)
    create_error_log(__method__, 'csrf_error', ex)

    if request.xhr?
      head :bad_request
    else
      redirect_to error_pages_csrf_error_path(via: current_via) unless performed?
    end
  end
end
