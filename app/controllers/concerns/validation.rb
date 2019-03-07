require 'active_support/concern'

module Concerns::Validation
  extend ActiveSupport::Concern
  include Concerns::ExceptionHandler
  include CrawlersHelper
  include PathsHelper
  include SearchHistoriesHelper

  included do

  end

  def require_login!
    return if user_signed_in?
    if request.xhr?
      head :unauthorized
    else
      redirect_to root_path_for(controller: controller_name), alert: t('before_sign_in.need_login_html', url: kick_out_error_path('need_login'))
    end
  end

  def valid_uid?(uid = nil)
    uid ||= params[:uid]
    twitter_user = TwitterUser.new(uid: uid)
    return true if twitter_user.valid_uid?

    if request.xhr?
      head :bad_request
    else
      message = twitter_user.errors.full_messages.join(t('dictionary.delim'))
      redirect_to root_path, alert: message
      create_search_error_log(uid.blank? ? '' : uid, '', __method__, message)
    end

    false
  end

  def twitter_user_persisted?(uid)
    return true if TwitterUser.exists?(uid: uid)

    if request.xhr?
      head :bad_request
      return false
    end

    if from_crawler? || !(controller_name == 'timelines' && action_name == 'show')
      message = t('application.not_found')
      redirect_to root_path_for(controller: controller_name), alert: message
      create_search_error_log(uid, '', __method__, message)
    else
      @screen_name = @tu.screen_name
      @redirect_path = timeline_path(screen_name: @screen_name)
      @via = params['via']
      render template: 'searches/create', layout: false
    end

    false
  end

  def twitter_db_user_persisted?(uid)
    return true if TwitterDB::User.exists?(uid: uid)

    logger.warn "#{controller_name}##{action_name}: TwitterDB::User not found. #{uid}"
    CreateTwitterDBUserWorker.perform_async([uid])
    true
  rescue => e
    logger.warn "#{controller_name}##{action_name}: TwitterDB::User not found. #{e.class} #{e.message} #{uid}"
    false
  end

  def searched_uid?(uid)
    return true if QueueingRequests.new(CreateTwitterUserWorker).exists?(uid)

    if request.xhr?
      head :bad_request
    else
      redirect_to root_path, alert: t('application.not_found')
    end

    false
  end

  def valid_screen_name?(screen_name = nil)
    screen_name ||= params[:screen_name]
    twitter_user = TwitterUser.new(screen_name: screen_name)

    if twitter_user.valid_screen_name?
      true
    else
      message = twitter_user.errors.full_messages.join(t('dictionary.delim'))
      redirect_to root_path_for(controller: controller_name), alert: message
      create_search_error_log(-1, screen_name, __method__, message)
      false
    end
  end

  # The user can see a result page if the user is signed in and a record of TwitterUser exists.
  def can_see_forbidden_or_not_found?(condition)
    user_signed_in? && TwitterUser.exists?(condition)
  end

  def forbidden_screen_name?(screen_name = nil)
    screen_name ||= params[:screen_name]
    if ForbiddenUser.exists?(screen_name: screen_name) && !can_see_forbidden_or_not_found?(screen_name: screen_name)
      message = forbidden_message(screen_name)
      redirect_to root_path_for(controller: controller_name), alert: message
      create_search_error_log(-1, screen_name, __method__, message)
      true
    else
      false
    end
  end

  def not_found_screen_name?(screen_name = nil)
    screen_name ||= params[:screen_name]
    if NotFoundUser.exists?(screen_name: screen_name) && !can_see_forbidden_or_not_found?(screen_name: screen_name)
      message = not_found_message(screen_name)
      redirect_to root_path_for(controller: controller_name), alert: message
      create_search_error_log(-1, screen_name, __method__, message)
      true
    else
      false
    end
  end

  def blocked_search?(twitter_user)
    return false unless user_signed_in?
    current_user.api_client.user_timeline(twitter_user.uid.to_i, count: 1)
    false
  rescue => e
    if e.message.start_with?('You have been blocked')
      if request.xhr?
        head :bad_request
        return true
      end

      message = blocked_message(twitter_user.screen_name)
      redirect_to root_path_for(controller: controller_name), alert: message
      create_search_error_log(twitter_user.uid, twitter_user.screen_name, __method__, message)
      true
    else
      # This is a special case because it call redirect_to and returns false.
      twitter_exception_handler(e, twitter_user.screen_name)
      false
    end
  end

  def authorized_search?(twitter_user)
    redirect_path = root_path_for(controller: controller_name)

    if twitter_user.suspended_account? && !can_see_forbidden_or_not_found?(uid: twitter_user.uid)
      message = suspended_message(twitter_user.screen_name)
      redirect_to redirect_path, alert: message
      create_search_error_log(twitter_user.uid, twitter_user.screen_name, __method__, message)
      return false
    end

    return true if twitter_user.public_account?
    return true if user_signed_in? && twitter_user.readable_by?(current_user)

    if request.xhr?
      head :bad_request
    else
      message = protected_message(twitter_user.screen_name)
      redirect_to redirect_path, alert: message
      create_search_error_log(twitter_user.uid, twitter_user.screen_name, __method__, message)
    end

    false
  rescue => e
    twitter_exception_handler(e, twitter_user.screen_name)
    false
  end

  def too_many_searches?(twitter_user, allow_search_history: true)
    return false if from_crawler? || search_histories_remaining > 0
    return false if allow_search_history && latest_search_histories.any? { |history| history.uid.to_i == twitter_user.uid.to_i }

    if request.xhr?
      render json: {error: 'too_many_searches'}, status: :bad_request
      return true
    end

    message =
        if user_signed_in?
          t('after_sign_in.too_many_searches_html', limit: search_histories_limit)
        else
          t('before_sign_in.too_many_searches_html', limit: search_histories_limit, url: kick_out_error_path('too_many_searches'))
        end

    redirect_to root_path, alert: message
    create_search_error_log(twitter_user.uid, twitter_user.screen_name, __method__, message)
    true
  end

  def too_many_requests?(twitter_user)
    return false if from_crawler? || !user_signed_in?
    return false unless TooManyRequestsQueue.new.exists?(current_user_id)

    if request.xhr?
      head :bad_request
      return true
    end

    limit = request_context_client.rate_limit
    reset_in = [limit.friend_ids, limit.follower_ids, limit.users].select {|l| l[:remaining] == 0}.map {|l| l[:reset_in]}.max
    message = too_many_requests_message(reset_in)
    redirect_to root_path, alert: message
    create_search_error_log(twitter_user.uid, twitter_user.screen_name, __method__, message)
    true
  rescue => e
    # This is a special case because it call redirect_to and returns false.
    twitter_exception_handler(e, twitter_user.screen_name)
    false
  end

  def has_already_purchased?
    return false if current_user.orders.none? {|o| !o.expired?}

    if request.xhr?
      head :bad_request
    else
      redirect_to root_path, alert: t('after_sign_in.has_already_purchased_html', url: settings_path)
    end

    true
  end
end
