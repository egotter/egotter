require 'active_support/concern'

module Concerns::InternalServerErrorHandler
  extend ActiveSupport::Concern
  include Concerns::AlertMessagesConcern
  include Concerns::DebugConcern

  included do
    rescue_from Exception, with: :handle_general_error
    rescue_from Rack::Timeout::RequestTimeoutException, with: :handle_request_timeout
    rescue_from ActionController::InvalidAuthenticityToken, with: :handle_csrf_error
  end

  private

  def handle_general_error(ex)
    logger.warn "rescue_from Exception: #{ex.class} #{ex.message.truncate(100)} #{request_details}"
    notify_airbrake(ex, request_details_json)

    message = internal_server_error_message
    create_search_error_log(__method__, message, ex)

    if request.xhr?
      render json: {error: message}, status: :internal_server_error
    else
      self.sidebar_disabled = true
      flash.now[:alert] = message
      render template: 'home/new', formats: %i(html), status: :internal_server_error unless performed?
    end
  end

  def handle_request_timeout(ex)
    logger.warn "#{ex.class} #{ex.message.truncate(100)} #{request_details}"
    notify_airbrake(ex, request_details_json)

    if request.xhr?
      render json: {error: ex.message.truncate(100)}, status: :request_timeout
    else
      self.sidebar_disabled = true
      flash.now[:alert] = request_timeout_message
      render template: 'home/new', formats: %i(html), status: :request_timeout
    end
  end

  def handle_csrf_error(ex)
    logger.info "#{ex.class} #{request_details}"
    notify_airbrake(ex, request_details_json)

    if request.xhr?
      render json: {error: ex.message.truncate(100)}, status: :bad_request
    else
      screen_name = params[:screen_name].to_s.strip.remove /^@/
      if screen_name.match? Validations::ScreenNameValidator::REGEXP
        search = timeline_path(screen_name: screen_name, via: current_via('invalid_token_and_recover'))
        sign_in = sign_in_path(via: current_via('invalid_token_and_recover'), redirect_path: search)

        if recoverable_request?
          redirect_to root_path, alert: t('application.invalid_token.ready_to_search_html', user: screen_name, url1: search, url2: sign_in)
        else
          redirect_to root_path, alert: t('application.invalid_token.session_expired_and_recover_html', user: screen_name, url1: search, url2: sign_in)
        end
      else
        redirect_to root_path, alert: t('application.invalid_token.session_expired_html', url: sign_in_path(via: "#{controller_name}/#{action_name}/invalid_token"))
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

  def request_timeout_message
    screen_name = params[:screen_name] || @twitter_user&.screen_name

    if screen_name.present?
      url = timeline_path(screen_name: screen_name, via: current_via('request_timeout'))
      t('application.request_timeout_with_recovery_html', user: screen_name, url: url)
    else
      t('application.request_timeout_html')
    end
  end
end
