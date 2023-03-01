require 'active_support/concern'

module RequestErrorHandler
  extend ActiveSupport::Concern
  include Logging

  included do
    rescue_from StandardError, with: :handle_general_error
    rescue_from Rack::Timeout::RequestTimeoutException, with: :handle_request_timeout
    rescue_from ActionController::InvalidAuthenticityToken, with: :handle_csrf_error
    rescue_from ActiveRecord::ConnectionNotEstablished, with: :handle_database_error
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
    SendMessageToSlackWorker.perform_async(:web_timeout, "#{ex.inspect} #{request_details}") rescue nil

    if request.xhr?
      head :request_timeout
    else
      redirect_to error_pages_request_timeout_error_path(via: current_via) unless performed?
    end
  end

  def handle_csrf_error(ex)
    Airbag.info ex.inspect, request_details

    if request.xhr?
      head :bad_request
    else
      redirect_to error_pages_csrf_error_path(via: current_via) unless performed?
    end
  end

  def handle_database_error(ex)
    Airbag.exception ex

    if request.xhr?
      head :internal_server_error
    else
      redirect_to error_pages_database_error_path(via: current_via) unless performed?
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
        fullpath: request.fullpath,
        referer: request.referer,
        user_agent: user_signed_in? ? nil : safe_user_agent,
        params: request.method == 'GET' ? nil : concatenated_params,
        twitter_user_id: @twitter_user&.id,
    }.compact
  end
end
