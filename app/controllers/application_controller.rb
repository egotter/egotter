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
    if e
      logger.warn "#{request.xhr?} #{request.device_type} #{current_user_id} #{params.inspect}"
    end rescue nil
    if request.xhr?
      render nothing: true, status: 500
    else
      sign_in_link = view_context.link_to(t('dictionary.sign_in'), welcome_path(via: "#{controller_name}/#{action_name}/invalid_token"))
      redirect_to root_path, alert: t('before_sign_in.session_expired', sign_in_link: sign_in_link)
    end
  end

  def not_found
    logger.warn "#{request.method} #{request.fullpath} #{current_user_id} #{request.device_type} #{request.browser}"
    redirect_to root_path, alert: t('before_sign_in.that_page_doesnt_exist')
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
    path.match(%r{^/(one_sided_friends|unfriends|inactive_friends|friends|searches)}) ? path : root_path
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
