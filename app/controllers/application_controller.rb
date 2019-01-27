class ApplicationController < ActionController::Base
  include ApplicationHelper
  include UsersHelper
  include TwitterUsersHelper
  include CrawlersHelper
  include SessionsHelper
  include Concerns::Validation
  include Concerns::Logging

  # Avoid `uninitialized constant`
  TwitterUser
  TwitterDB::User

  before_action :set_locale

  def set_locale
    I18n.locale = I18n.available_locales.map(&:to_s).include?(params[:locale]) ? params[:locale] : I18n.default_locale
  end

  def default_url_options(options = {})
    {locale: I18n.locale}.merge options
  end

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from Exception do |ex|
    puts "rescue_from Exception: #{ex.class} #{ex.message}"
    logger.warn "rescue_from Exception: #{ex.class} #{ex.message} #{debug_str}"
    logger.info ex.backtrace.join("\n")
    request.xhr? ? head(:internal_server_error) : render_500
  end

  rescue_from ActionController::InvalidAuthenticityToken, with: :invalid_token

  def invalid_token
    logger.info "Invalid token: #{debug_str}"

    return head :bad_request if request.xhr?

    screen_name = params[:screen_name].to_s.strip.remove /^@/
    unless screen_name.match(Validations::ScreenNameValidator::REGEXP)
      return redirect_to root_path, alert: t('application.invalid_token.session_expired_html', url: sign_in_path(via: "#{controller_name}/#{action_name}/invalid_token"))
    end

    search = timeline_path(screen_name: screen_name)
    sign_in = sign_in_path(via: "#{controller_name}/#{action_name}/invalid_token_and_recover", redirect_path: search)

    if recoverable_request?
      logger.warn "Recoverable CSRF token error #{fingerprint} #{debug_str}"
      return redirect_to root_path, alert: t('application.invalid_token.ready_to_search_html', user: screen_name, url1: search, url2: sign_in)
    end

    redirect_to root_path, alert: t('application.invalid_token.session_expired_and_recover_html', user: screen_name, url1: search, url2: sign_in)
  end

  def not_found
    logger.info "Not found: #{debug_str}"

    return head :not_found if request.xhr?
    return render_404 if from_crawler? || request.method != 'GET'

    if params['screen_name'].to_s.match(Validations::ScreenNameValidator::REGEXP) && request.path == '/searches'
      @screen_name = params['screen_name']
      @redirect_path = timeline_path(screen_name: @screen_name)
      @via = params['via']
      return render template: 'searches/create', layout: false
    end

    # if params['from'].to_s.match(Validations::ScreenNameValidator::REGEXP) && request.path == '/profile'
    #   @screen_name = params['from']
    #   @redirect_path = timeline_path(screen_name: @screen_name)
    #   @via = params['via']
    #   return render template: 'searches/create', layout: false
    # end

    if request.fullpath.match(%r{^/https:/egotter\.com(.+)})
      redirect = "https://egotter.com#{$1}"
      logger.info "Redirect to: #{redirect}"
      return redirect_to redirect, status: 301
    end

    render_404
  end

  def recoverable_request?
    %i(pc smartphone).include?(request.device_type) && !request.xhr? &&
      params['screen_name'].to_s.match(Validations::ScreenNameValidator::REGEXP) &&
      controller_name == 'searches' && action_name == 'create'
      # session[:fingerprint].present? &&
      # SearchLog.exists?(created_at: 3.hours.ago..Time.zone.now, session_id: session[:fingerprint])
  end

  def debug_str
    "#{request.method} #{current_user_id} #{request.device_type} #{request.browser} #{!!request.xhr?} #{request.fullpath} #{request.referer} #{params.inspect}"
  end

  # https://github.com/plataformatec/devise/issues/1390
  def new_session_path(scope)
    root_path
  end

  def basic_auth
    authenticate_or_request_with_http_basic do |user, pass|
      user == ENV['DEBUG_USERNAME'] && pass == ENV['DEBUG_PASSWORD']
    end
  end

  SANITIZE_REDIRECT_PATH_REGEXP = Regexp.union(Search::API_V1_NAMES.map(&:to_s) + %w(conversations clusters searches timelines scores))

  def sanitized_redirect_path(path)
    path.match?(SANITIZE_REDIRECT_PATH_REGEXP) ? path : root_path
  end

  def after_sign_in_path_for(resource)
    redirect_path =
        if session[:redirect_path]
          sanitized_redirect_path(session.delete(:redirect_path))
        else
          root_path
        end

    redirect_path += redirect_path.include?('?') ? '&' : '?'
    redirect_path + 'follow_dialog=1&share_dialog=1'
  end

  def after_sign_out_path_for(resource)
    session[:sign_out_from] = request.protocol + request.host_with_port + sign_out_path
    root_path
  end

  def render_404
    self.sidebar_disabled = true
    flash.now[:alert] = t('application.not_found')
    render template: 'home/new', formats: %i(html), status: 404
  end

  def render_500
    self.sidebar_disabled = true
    screen_name = params[:screen_name] || @twitter_user&.screen_name
    if screen_name.present?
      flash.now[:alert] = t('application.internal_server_error_with_recovery_html', user: screen_name, url: timeline_path(screen_name: screen_name))
    else
      flash.now[:alert] = t('application.internal_server_error')
    end
    render template: 'home/new', formats: %i(html), status: 500
  end
end
