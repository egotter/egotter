class ApplicationController < ActionController::Base
  include ApplicationHelper

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from ActionController::InvalidAuthenticityToken do |e|
    if e
      logger.warn "#{self.class}##{action_name}: #{e.class} #{request.xhr? ? 'true' : 'false'} #{request.device_type} #{current_user_id} #{params.inspect}"
    end rescue nil
    if request.xhr?
      render nothing: true, status: 500
    else
      redirect_to root_path, alert: t('before_sign_in.session_expired', sign_in_link: view_context.link_to(t('dictionary.sign_in'), welcome_path))
    end
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

  def after_sign_in_path_for(resource)
    root_path
  end

  def after_sign_out_path_for(resource)
    session[:sign_out_from] = request.protocol + request.host_with_port + sign_out_path
    root_path
  end
end
