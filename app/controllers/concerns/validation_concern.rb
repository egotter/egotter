require 'active_support/concern'

module Concerns::ValidationConcern
  extend ActiveSupport::Concern
  include Concerns::TwitterExceptionHandler
  include PathsHelper
  include SearchHistoriesHelper

  included do

  end

  def require_login!
    return if user_signed_in?

    message =
        if request.xhr?
          t('before_sign_in.ajax.need_login_html', url: kick_out_error_path('need_login'))
        else
          t('before_sign_in.need_login_html', url: kick_out_error_path('need_login'))
        end
    respond_with_error(:unauthorized, message)
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
    return true if TwitterUser.exists?(uid: uid)

    if !from_crawler? && controller_name == 'timelines' && action_name == 'show'
      @screen_name = @twitter_user.screen_name
      @redirect_path = timeline_path(screen_name: @screen_name)
      @via = params['via']
      render template: 'searches/create', formats: %i(html), layout: false
    else
      respond_with_error(:bad_request, t('application.not_found'))
    end

    false
  end

  def twitter_db_user_persisted?(uid)
    CreateTwitterDBUserWorker.perform_async([uid])
    TwitterDB::User.exists?(uid: uid)
  end

  def searched_uid?(uid)
    if QueueingRequests.new(CreateTwitterUserWorker).exists?(uid)
      true
    else
      respond_with_error(:bad_request, t('application.not_found'))
      false
    end
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

  def forbidden_screen_name?(screen_name = nil)
    screen_name ||= params[:screen_name]

    if ForbiddenUser.exists?(screen_name: screen_name) || forbidden_user?(screen_name)
      redirect_to forbidden_path(screen_name: screen_name)
      true
    else
      false
    end
  end

  def forbidden_user?(screen_name)
    request_context_client.user(screen_name)
    false
  rescue => e
    if e.message == 'User has been suspended.'
      CreateForbiddenUserWorker.perform_async(screen_name)
      true
    else
      false
    end
  end

  def not_found_screen_name?(screen_name = nil)
    screen_name ||= params[:screen_name]

    if NotFoundUser.exists?(screen_name: screen_name) || not_found_user?(screen_name)
      redirect_to not_found_path(screen_name: screen_name)
      true
    else
      false
    end
  end

  def not_found_user?(screen_name)
    request_context_client.user(screen_name)
    false
  rescue => e
    if e.message == 'User not found.'
      CreateNotFoundUserWorker.perform_async(screen_name)
      true
    else
      false
    end
  end

  def blocked_user?(screen_name)
    if user_signed_in?
      request_context_client.user_timeline(screen_name, count: 1)
      false
    else
      false
    end
  rescue => e
    if e.message.start_with?('You have been blocked')
      true
    else
      false
    end
  end

  def blocked_search?(twitter_user)
    blocked = blocked_user?(twitter_user.screen_name)
    redirect_to blocked_path(screen_name: twitter_user.screen_name) if blocked
    blocked
  end

  def protected_user?(screen_name)
    if user_signed_in?
      request_context_client.user_timeline(screen_name, count: 1)
      false
    else
      user = request_context_client.user(screen_name)
      user[:protected]
    end
  rescue => e
    if e.message == 'Not authorized.'
      true
    else
      false
    end
  end

  def protected_search?(twitter_user)
    protected = protected_user?(twitter_user.screen_name)
    redirect_to protected_path(screen_name: twitter_user.screen_name) if protected
    protected
  rescue => e
    respond_with_error(:bad_request, twitter_exception_messages(e, twitter_user.screen_name))
    false
  end

  def screen_name_changed?(twitter_user)
    latest = TwitterUser.latest_by(uid: twitter_user.uid)
    latest && latest&.screen_name != twitter_user.screen_name
  end

  def too_many_searches?(twitter_user)
    return false if from_crawler? || search_histories_remaining > 0
    return false if current_search_histories.any? { |history| history.uid == twitter_user.uid }

    respond_with_error(:bad_request, too_many_searches_message)
    true
  end

  def too_many_searches_message
    if user_signed_in?
      t('after_sign_in.too_many_searches_html', limit: search_histories_limit, url: pricing_path)
    else
      t('before_sign_in.too_many_searches_html', limit: search_histories_limit, url: kick_out_error_path('too_many_searches'))
    end
  end

  def too_many_requests?(twitter_user)
    return false if from_crawler? || !user_signed_in?
    return false unless TooManyRequestsQueue.new.exists?(current_user_id)

    respond_with_error(:bad_request, too_many_requests_message)
    true
  rescue => e
    # This is a special case because it call redirect_to and returns false.
    respond_with_error(:bad_request, twitter_exception_messages(e, twitter_user.screen_name))
    false
  end

  def has_already_purchased?
    return false if current_user.orders.unexpired.none?

    respond_with_error(:bad_request, t('after_sign_in.has_already_purchased_html', url: settings_path))
    true
  end
end
