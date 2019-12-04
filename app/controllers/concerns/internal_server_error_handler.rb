require 'active_support/concern'

module Concerns::InternalServerErrorHandler
  extend ActiveSupport::Concern
  include Concerns::DebugConcern

  included do
    rescue_from Exception, with: :handle_general_error
    rescue_from Rack::Timeout::RequestTimeoutException, with: :handle_request_timeout
    rescue_from ActionController::InvalidAuthenticityToken, with: :handle_csrf_error
  end

  private

  def handle_general_error(ex)
    logger.warn "rescue_from Exception: #{ex.class} #{ex.message.truncate(100)} #{request_details}"
    logger.info ex.backtrace.join("\n")

    if request.xhr?
      render json: {error: ex.message.truncate(100)}, status: :internal_server_error
    else
      self.sidebar_disabled = true
      flash.now[:alert] = internal_server_error_message
      render template: 'home/new', formats: %i(html), status: :internal_server_error
    end
  end

  def handle_request_timeout(ex)
    logger.warn "#{ex.class} #{ex.message.truncate(100)} #{request_details}"

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

    if request.xhr?
      render json: {error: ex.message.truncate(100)}, status: :bad_request
    else
      screen_name = params[:screen_name].to_s.strip.remove /^@/
      if screen_name.match? Validations::ScreenNameValidator::REGEXP
        search = timeline_path(screen_name: screen_name, via: build_via('invalid_token_and_recover'))
        sign_in = sign_in_path(via: build_via('invalid_token_and_recover'), redirect_path: search)

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
        fingerprint.present?
    # SearchLog.exists?(created_at: 3.hours.ago..Time.zone.now, session_id: session[:fingerprint])
  end

  def request_timeout_message
    screen_name = params[:screen_name] || @twitter_user&.screen_name

    if screen_name.present?
      url = timeline_path(screen_name: screen_name, via: build_via('request_timeout'))
      t('application.request_timeout_with_recovery_html', user: screen_name, url: url)
    else
      t('application.request_timeout_html')
    end
  end

  def internal_server_error_message
    screen_name = params[:screen_name] || @twitter_user&.screen_name

    if screen_name.present?
      url = timeline_path(screen_name: screen_name, via: build_via('server_error'))
      t('application.internal_server_error_with_recovery_html', user: screen_name, url: url)
    else
      t('application.internal_server_error')
    end
  end
end
