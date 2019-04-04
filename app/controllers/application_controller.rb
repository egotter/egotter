class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Concerns::InternalServerErrorHandler
  include Concerns::RoutingErrorHandler
  include Concerns::ApiClientConcern
  include Concerns::UsersConcern
  include Concerns::TwitterUsersConcern
  include CrawlersHelper
  include Concerns::SessionsConcern
  include Concerns::ValidationConcern
  include Concerns::Logging

  # Avoid `uninitialized constant` or `Unable to autoload constant`
  ::TwitterUser
  ::TwitterDB::User
  ::Api::V1

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

  # https://github.com/plataformatec/devise/issues/1390
  def new_session_path(scope)
    root_path
  end

  def basic_auth
    authenticate_or_request_with_http_basic do |user, pass|
      user == ENV['DEBUG_USERNAME'] && pass == ENV['DEBUG_PASSWORD']
    end
  end

  def referer_is_tokimeki_unfollow?
    request.referer.to_s.match? %r{\Ahttps?://(egotter.com|localhost:3000)/tokimeki_unfollow/cleanup}
  end

  def after_sign_out_path_for(resource)
    session[:sign_out_from] = request.protocol + request.host_with_port + sign_out_path
    root_path
  end

  def respond_with_error(code, message, ex = nil)
    location = (caller[0][/`([^']*)'/, 1] rescue '')

    if request.xhr?
      render json: {error: location.remove(/\?/), message: message}, status: code
    else
      redirect_to root_path_for(controller: controller_name), alert: message
    end

    create_search_error_log(location, message, ex)
  end
end
