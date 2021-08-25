class ApplicationController < ActionController::Base
  include RequestErrorHandler
  include NewrelicConcern
  include SearchCountLimitationConcern
  include ApplicationHelper
  include InternalServerErrorHandler
  include RoutingErrorHandler
  include TwitterErrorHandler
  include ApiClientConcern
  include UsersConcern
  include TwitterUsersConcern
  include CrawlersHelper
  include SessionsConcern
  include ValidationConcern
  include BypassFlashMessagesConcern
  include Logging

  before_action :reject_spam_ip!, if: -> { controller_name != 'error_pages' }
  before_action :current_user_authorized?, if: -> { controller_name != 'error_pages' }
  before_action :current_user_has_dm_permission?, if: -> { controller_name != 'error_pages' }
  before_action :current_user_not_blocker?, if: -> { controller_name != 'error_pages' }

  skip_before_action :track_ahoy_visit, if: -> { apache_bench? }

  after_action :create_access_log, if: -> { create_access_log? }
  after_action :create_access_day, if: -> { create_access_log? }

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
    root_path(via: current_via('new_session'))
  end

  def basic_auth
    authenticate_or_request_with_http_basic do |user, pass|
      user == ENV['DEBUG_USERNAME'] && pass == ENV['DEBUG_PASSWORD']
    end
  end

  def referer_is_tokimeki_unfollow?
    request.referer.to_s.match? %r{\Ahttps?://(egotter.com|localhost:3000)/tokimeki_unfollow/cleanup}
  end

  def respond_with_error(code, message, ex = nil)
    location = (caller[0][/`([^']*)'/, 1] rescue '')

    if request.xhr?
      render json: {message: message}, status: code
    else
      redirect_to subroot_path(via: 'respond_with_error'), alert: message
    end

    create_error_log(location, message, ex)
  end
end
