require 'active_support/concern'

module RequestErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :handle_general_error
    rescue_from Rack::Timeout::RequestTimeoutException, with: :handle_request_timeout
    rescue_from ActionController::InvalidAuthenticityToken, with: :handle_csrf_error
  end

  private

  def handle_general_error(ex)
    Airbag.exception ex, request_details

    if request.xhr?
      head :internal_server_error
    else
      redirect_to error_pages_internal_server_error_path(via: current_via) unless performed?
    end
  end

  def handle_request_timeout(ex)
    Airbag.exception ex, request_details

    if request.xhr?
      head :request_timeout
    else
      redirect_to error_pages_request_timeout_error_path(via: current_via) unless performed?
    end
  end

  def handle_csrf_error(ex)
    if request.xhr?
      head :bad_request
    else
      redirect_to error_pages_csrf_error_path(via: current_via) unless performed?
    end
  end

  private

  def request_details
    {
        user_id: user_signed_in? ? current_user.id : -1,
        method: request.method,
        device_type: request.device_type,
        browser: request.browser,
        xhr: request.xhr?,
        full_path: request.fullpath,
        referer: request.referer,
        user_agent: user_signed_in? ? nil : request.user_agent,
        params: request.method == 'GET' ? nil : request.query_parameters.merge(request.request_parameters).except(:locale, :utf8, :authenticity_token),
        twitter_user_id: @twitter_user&.id,
    }.compact
  end
end
