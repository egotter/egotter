class ApplicationController < ActionController::Base
  include ApplicationHelper

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

  rescue_from ActionController::InvalidAuthenticityToken do |e|
    if request.referer.present? && !request.referer.match(%r{^https://egotter.com})
      params[:screen_name][0] = '' if params[:screen_name]&.start_with?('@')

      if params['screen_name']&.match(Validations::ScreenNameValidator::REGEXP) && controller_name == 'searches' && action_name == 'create'
        logger.warn "cross domain post #{request.device_type} #{current_user_id} #{request.fullpath} #{request.referer} #{params['screen_name']}"
        _sign_in_path = sign_in_path via: "#{controller_name}/#{action_name}/cross_domain_post_and_recover", redirect_path: search_path(screen_name: params[:screen_name])
        redirect_to root_path, alert: t('before_sign_in.cross_domain_post_and_recover_html', user: params[:screen_name], sign_in_path: _sign_in_path)
      else
        logger.warn "cross domain post #{request.device_type} #{current_user_id} #{request.fullpath} #{request.referer} #{params.inspect}"
        _sign_in_path = sign_in_path via: "#{controller_name}/#{action_name}/cross_domain_post"
        redirect_to root_path, alert: t('before_sign_in.cross_domain_post_html', sign_in_path: _sign_in_path)
      end
    else
      recover = recover_invalid_token?
      logger.warn "CSRF token error (#{recover}) #{session[:fingerprint]&.truncate(15)} #{request.method} #{!!request.xhr?} #{request.device_type} #{current_user_id} #{request.fullpath} #{request.user_agent} #{params.inspect}"

      if recover
        _sign_in_path = sign_in_path via: "#{controller_name}/#{action_name}/invalid_token_and_recover", redirect_path: search_path(screen_name: params[:screen_name])
        redirect_to root_path, alert: t('before_sign_in.session_expired_and_recover_html', user: params[:screen_name], sign_in_path: _sign_in_path)
      else
        if request.xhr?
          head :internal_server_error
        else
          redirect_to root_path, alert: t('before_sign_in.session_expired_html', sign_in_path: welcome_path(via: "#{controller_name}/#{action_name}/invalid_token"))
        end
      end
    end
  end

  def not_found
    if params['screen_name']&.match(Validations::ScreenNameValidator::REGEXP) && request.path == '/searches'
      @screen_name = params['screen_name']
      @redirect_path = search_path(screen_name: @screen_name)
      @via = params['via']
      render template: 'searches/create', layout: false
    elsif request.fullpath.match %r{^/https:/egotter\.com(.+)}
      redirect_url = "https://egotter.com#{$1}"
      logger.info "redirect to #{redirect_url} #{current_user_id} #{request.device_type} #{request.browser} #{request.referer}"
      redirect_to redirect_url, status: 301
    else
      unless request.fullpath.match %r{^/search_results/}
        logger.warn "#{request.method} #{request.fullpath} #{current_user_id} #{request.device_type} #{request.browser}"
      end
      request.xhr? ? head(:not_found) : redirect_to(root_path, alert: t('before_sign_in.that_page_doesnt_exist'))
    end
  end

  def recover_invalid_token?
    %i(pc smartphone).include?(request.device_type) && !request.xhr? &&
      !!params['screen_name']&.match(Validations::ScreenNameValidator::REGEXP) &&
      controller_name == 'searches' && action_name == 'create' && session[:fingerprint].present? &&
      SearchLog.exists?(created_at: 3.hours.ago..Time.zone.now, session_id: session[:fingerprint])
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
    path.match(%r{^/(one_sided_friends|unfriends|inactive_friends|friends|conversations|clusters|searches)}) ? path : root_path
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
end
