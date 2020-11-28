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
    handle_request_error(ex) if Rails.env.production?

    message = internal_server_error_message
    create_error_log(__method__, message, ex)

    if request.xhr?
      render json: {message: message}, status: :internal_server_error
    else
      render file: "#{Rails.root}/public/500.html", status: :internal_server_error, layout: false unless performed?
    end
  end

  def handle_request_timeout(ex)
    handle_request_error(ex) if Rails.env.production?

    if request.xhr?
      render json: {error: ex.message.truncate(100)}, status: :request_timeout
    else
      render file: "#{Rails.root}/public/408.html", status: :request_timeout, layout: false unless performed?
    end
  end

  def handle_csrf_error(ex)
    logger.info "##{__method__}: #{ex.class} #{request_details}"

    if request.xhr?
      render json: {error: ex.message.truncate(100)}, status: :bad_request
    else
      screen_name = params[:screen_name].to_s.strip.remove /^@/
      if screen_name.match? Validations::ScreenNameValidator::REGEXP
        search = timeline_path(screen_name: screen_name, via: current_via('invalid_token_and_recover'))
        sign_in = sign_in_path(via: current_via('invalid_token_and_recover'), redirect_path: search)

        if recoverable_request?
          redirect_to root_path(via: current_via('ready_to_search')), alert: t('application.invalid_token.ready_to_search_html', user: screen_name, url1: search, url2: sign_in)
        else
          redirect_to root_path(via: current_via('session_expired_and_recover')), alert: t('application.invalid_token.session_expired_and_recover_html', user: screen_name, url1: search, url2: sign_in)
        end
      else
        redirect_to root_path(via: current_via('session_expired')), alert: t('application.invalid_token.session_expired_html', url: sign_in_path(via: "#{controller_name}/#{action_name}/invalid_token"))
      end
    end
  end

  def recoverable_request?
    %i(pc smartphone).include?(request.device_type) &&
        !request.xhr? &&
        params['screen_name'].to_s.match?(Validations::ScreenNameValidator::REGEXP) &&
        controller_name == 'searches' &&
        action_name == 'create' &&
        egotter_visit_id.present?
    # SearchLog.exists?(created_at: 3.hours.ago..Time.zone.now, session_id: session[:egotter_visit_id])
  end
end
