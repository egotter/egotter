class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Concerns::Logging

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

  rescue_from ActionController::InvalidAuthenticityToken, with: :invalid_token

  def invalid_token
    logger.info "Invalid token: #{debug_str}"

    if request.xhr?
      return head(:bad_request)
    end

    screen_name = params[:screen_name].to_s.strip.remove /^@/
    if screen_name.blank? || !screen_name.match(Validations::ScreenNameValidator::REGEXP)
      return redirect_to root_path, alert: t('application.invalid_token.session_expired_html', url: welcome_path(via: "#{controller_name}/#{action_name}/invalid_token"))
    end

    search = search_path(screen_name: screen_name)
    sign_in = sign_in_path(via: "#{controller_name}/#{action_name}/invalid_token_and_recover", redirect_path: search)

    if recoverable_request?
      logger.warn "Recoverable CSRF token error #{session[:fingerprint]&.truncate(15)} #{debug_str}"
      return redirect_to root_path, alert: t('application.invalid_token.ready_to_search_html', user: screen_name, url1: search, url2: sign_in)
    end

    redirect_to root_path, alert: t('application.invalid_token.session_expired_and_recover_html', user: screen_name, url1: search, url2: sign_in)
  end

  def not_found
    logger.info "Not found: #{debug_str}"

    if request.from_crawler? || from_minor_crawler?(request.user_agent) || request.method != 'GET' || request.xhr?
      return head :not_found
    end

    if params['screen_name'].to_s.match(Validations::ScreenNameValidator::REGEXP) && request.path == '/searches'
      @screen_name = params['screen_name']
      @redirect_path = search_path(screen_name: @screen_name)
      @via = params['via']
      return render template: 'searches/create', layout: false
    end

    if params['from'].to_s.match(Validations::ScreenNameValidator::REGEXP) && request.path == '/profile'
      @screen_name = params['from']
      @redirect_path = search_path(screen_name: @screen_name)
      @via = params['via']
      return render template: 'searches/create', layout: false
    end

    if request.fullpath.match(%r{^/https:/egotter\.com(.+)})
      redirect = "https://egotter.com#{$1}"
      logger.info "Redirect to: #{redirect}"
      return redirect_to redirect, status: 301
    end

    flash.now[:alert] = t('before_sign_in.that_page_doesnt_exist')
    render template: 'searches/new', status: 404
  end

  def recoverable_request?
    %i(pc smartphone).include?(request.device_type) && !request.xhr? &&
      params['screen_name'].to_s.match(Validations::ScreenNameValidator::REGEXP) &&
      controller_name == 'searches' && action_name == 'create'
      # session[:fingerprint].present? &&
      # SearchLog.exists?(created_at: 3.hours.ago..Time.zone.now, session_id: session[:fingerprint])
  end

  def debug_str
    "#{request.method} #{current_user_id} #{request.device_type} #{request.browser} #{request.xhr?} #{request.referer} #{params.inspect}"
  end

  # https://github.com/plataformatec/devise/issues/1390
  def new_session_path(scope)
    new_user_session_path(scope)
  end

  def basic_auth
    authenticate_or_request_with_http_basic do |user, pass|
      user == ENV['DEBUG_USERNAME'] && pass == ENV['DEBUG_PASSWORD']
    end
  end

  def sanitized_redirect_path(path)
    regexp = %r{^/(one_sided_friends|unfriends|inactive_friends|friends|conversations|clusters|searches|timelines|close_friends|scores)}
    path.match(regexp) ? path : root_path
  end

  def after_sign_in_path_for(resource)
    if session[:redirect_path]
      sanitized_redirect_path(session.delete(:redirect_path))
    else
      root_path
    end
  end

  def after_sign_out_path_for(resource)
    session[:sign_out_from] = request.protocol + request.host_with_port + sign_out_path
    root_path
  end

  def from_minor_crawler?(user_agent)
    user_agent.to_s.match /Applebot|Jooblebot|SBooksNet|AdsBot-Google-Mobile|FlipboardProxy|HeartRails_Capture|Mail\.RU_Bot|360Spider/
  end
end
