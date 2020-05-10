require 'active_support/concern'

module Concerns::ValidationConcern
  extend ActiveSupport::Concern
  include Concerns::AlertMessagesConcern
  include PathsHelper
  include SearchHistoriesHelper

  included do

  end

  def require_login!
    return if user_signed_in?

    if request.xhr?
      message = t('before_sign_in.ajax.need_login_html', url: kick_out_error_path('need_login'))
      respond_with_error(:unauthorized, message)
    else
      message = t('before_sign_in.need_login_html', url: sign_in_path(via: current_via(__method__), redirect_path: request.fullpath))
      create_search_error_log(__method__, message)
      flash.now[:alert] = message
      @has_error = true
      render template: 'home/new', formats: %i(html), status: :unauthorized
    end
  end

  def require_admin!
    return if user_signed_in? && current_user.admin?
    respond_with_error(:unauthorized, t('before_sign_in.need_login_html', url: kick_out_error_path('need_login')))
  end

  def valid_uid?(uid, only_validation: false)
    if Validations::UidValidator::REGEXP.match?(uid.to_s)
      true
    else
      unless only_validation
        respond_with_error(:bad_request, TwitterUser.human_attribute_name(:uid) + t('errors.messages.invalid'))
      end
      false
    end
  end

  def twitter_user_persisted?(uid)
    return true if TwitterUser.with_delay.exists?(uid: uid)

    if !from_crawler? && controller_name == 'timelines' && action_name == 'show'
      @screen_name = @twitter_user.screen_name
      @redirect_path = timeline_path(screen_name: @screen_name)
      @via = params['via'].presence || current_via('render_template')
      create_search_error_log(__method__, '')
      render template: 'searches/create', formats: %i(html), layout: false
    else
      respond_with_error(:bad_request, t('application.twitter_user_not_found'))
    end

    false
  end

  def twitter_db_user_persisted?(uid)
    CreateTwitterDBUserWorker.perform_async([uid], user_id: current_user_id, enqueued_by: 'twitter_db_user_persisted?')
    TwitterDB::User.exists?(uid: uid)
  end

  def signed_in_user_authorized?
    return true unless user_signed_in?

    if current_user.authorized?
      true
    else
      respond_with_error(:unauthorized, signed_in_user_not_authorized_message)
      false
    end
  end

  def enough_permission_level?
    return true unless user_signed_in?

    if current_user.notification_setting.enough_permission_level?
      true
    else
      url = sign_in_path(force_login: true, via: "#{controller_name}/#{action_name}/permission_level_not_enough")
      respond_with_error(:unauthorized, t('after_sign_in.permission_level_not_enough_html', user: current_user.screen_name, url: url))
      false
    end
  end

  def user_requested_self_search?
    screen_name = params[:screen_name]
    user_signed_in? && SearchRequestValidator.new(current_user).user_requested_self_search?(screen_name)
  end

  def valid_screen_name?(screen_name = nil)
    screen_name ||= params[:screen_name]

    if Validations::ScreenNameValidator::REGEXP.match?(screen_name)
      true
    else
      respond_with_error(:bad_request, TwitterUser.human_attribute_name(:screen_name) + t('errors.messages.invalid'))
      false
    end
  end

  def forbidden_screen_name?
    screen_name = params[:screen_name]

    if ForbiddenUser.exists?(screen_name: screen_name) || forbidden_user?(screen_name)
      redirect_to forbidden_path(screen_name: screen_name)
      true
    else
      false
    end
  end

  # It is possible not to call Twitter API in this method only when accessing from crawlers,
  # but since the same Twitter API is called in other places, it's a bit meaningless.
  # NOTE: The temporarily suspended users ( user[:suspended] == true ) are not checked.
  def forbidden_user?(screen_name)
    SearchRequestValidator.new(current_user).forbidden_user?(screen_name)
  end

  def not_found_screen_name?
    screen_name = params[:screen_name]

    if NotFoundUser.exists?(screen_name: screen_name) || not_found_user?(screen_name)
      redirect_to not_found_path(screen_name: screen_name)
      true
    else
      false
    end
  end

  # It is possible not to call Twitter API in this method only when accessing from crawlers,
  # but since the same Twitter API is called in other places, it's a bit meaningless.
  def not_found_user?(screen_name)
    SearchRequestValidator.new(current_user).not_found_user?(screen_name)
  end

  def blocked_user?(screen_name)
    SearchRequestValidator.new(current_user).blocked_user?(screen_name)
  end

  def blocked_search?(twitter_user)
    blocked_user?(twitter_user.screen_name).tap do |value|
      redirect_to blocked_path(screen_name: twitter_user.screen_name) if value
    end
  rescue => e
    respond_with_error(:bad_request, twitter_exception_messages(e, twitter_user.screen_name))
    false
  end

  def protected_user?(screen_name)
    SearchRequestValidator.new(current_user).protected_user?(screen_name)
  end

  def protected_search?(twitter_user)
    protected_user?(twitter_user.screen_name).tap do |value|
      redirect_to protected_path(screen_name: twitter_user.screen_name) if value
    end
  rescue => e
    respond_with_error(:bad_request, twitter_exception_messages(e, twitter_user.screen_name))
    false
  end

  def search_limitation_soft_limited?(user)
    return false if from_crawler?
    return false if user_signed_in?

    if SearchLimitation.soft_limited?(user)
      # Set a parameter notice_message instead of a real message to avoid ActionDispatch::Cookies::CookieOverflow
      set_bypassed_notice_message('search_limitation_soft_limited')
      redirect_to profile_path(screen_name: user[:screen_name])

      url = sign_in_path(via: current_via(__method__), redirect_path: request.fullpath)
      message = search_limitation_soft_limited_message(user[:screen_name], url)
      create_search_error_log(__method__, message)
      true
    else
      false
    end
  end

  def screen_name_changed?(twitter_user)
    latest = TwitterUser.latest_by(uid: twitter_user.uid)
    latest && latest.screen_name != twitter_user.screen_name
  end

  def too_many_searches?(twitter_user)
    return false if from_crawler?
    return false if SearchCountLimitation.remaining_search_count(user: current_user, session_id: egotter_visit_id) > 0
    return false if current_search_histories.any? { |history| history.uid == twitter_user.uid }

    message = too_many_searches_message

    if request.xhr?
      respond_with_error(:bad_request, message)
    else
      # Set a parameter notice_message instead of a real message to avoid ActionDispatch::Cookies::CookieOverflow
      set_bypassed_notice_message('too_many_searches')
      redirect_to profile_path(screen_name: twitter_user.screen_name)
      create_search_error_log(__method__, message)
    end

    true
  end

  # TODO Rename to too_many_api_requests?
  def too_many_requests?(twitter_user)
    return false if from_crawler? || !user_signed_in?
    return false unless TooManyRequestsUsers.new.exists?(current_user_id)

    reset_in = TooManyRequestsUsers.new.ttl(current_user_id)
    message = too_many_requests_message(reset_in || 900)

    if request.xhr?
      respond_with_error(:bad_request, message)
    else
      redirect_to profile_path(screen_name: twitter_user.screen_name), alert: message
      create_search_error_log(__method__, message)
    end

    true
  rescue => e
    # This is a special case because it call redirect_to and returns false.
    respond_with_error(:bad_request, twitter_exception_messages(e, twitter_user.screen_name))
    false
  end

  def has_already_purchased?
    return false unless current_user.has_valid_subscription?

    respond_with_error(:bad_request, t('after_sign_in.has_already_purchased_html', url: settings_path))
    true
  end
end
