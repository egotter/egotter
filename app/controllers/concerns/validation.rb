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
    respond_with_error(:unauthorized, t('before_sign_in.need_login_html', url: kick_out_error_path('need_login')))
  end

  def require_admin!
    return if user_signed_in? && current_user.admin?
    respond_with_error(:unauthorized, t('before_sign_in.need_login_html', url: kick_out_error_path('need_login')))
  end

  def valid_uid?(uid = nil, redirect: true)
    uid ||= params[:uid]

    if Validations::UidValidator::REGEXP.match?(uid.to_s)
      true
    else
      if redirect
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
      render template: 'searches/create', layout: false
    else
      respond_with_error(:bad_request, t('application.not_found'))
    end

    false
  end

  def twitter_db_user_persisted?(uid)
    return true if TwitterDB::User.exists?(uid: uid)

    logger.info "#{controller_name}##{action_name} #{__method__} TwitterDB::User not found and enqueue CreateTwitterDBUserWorker. #{uid}"
    CreateTwitterDBUserWorker.perform_async([uid])
    true
  rescue => e
    logger.warn "#{controller_name}##{action_name} #{__method__} TwitterDB::User not found and do nothing. #{e.class} #{e.message} #{uid}"
    false
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

  # The user can see a result page if the user is signed in and a record of TwitterUser exists.
  def can_see_forbidden_or_not_found?(condition)
    user_signed_in? && TwitterUser.exists?(condition)
  end

  def forbidden_screen_name?(screen_name = nil)
    screen_name ||= params[:screen_name]

    if ForbiddenUser.exists?(screen_name: screen_name) && !can_see_forbidden_or_not_found?(screen_name: screen_name)
      respond_with_error(:bad_request, forbidden_message(screen_name))
      true
    else
      false
    end
  end

  def not_found_screen_name?(screen_name = nil)
    screen_name ||= params[:screen_name]

    if NotFoundUser.exists?(screen_name: screen_name) && !can_see_forbidden_or_not_found?(screen_name: screen_name)
      respond_with_error(:bad_request, not_found_message(screen_name))
      true
    else
      false
    end
  end

  def blocked_search?(twitter_user)
    return false unless user_signed_in?
    request_context_client.user_timeline(twitter_user.uid, count: 1)
    false
  rescue => e
    if e.message.start_with?('You have been blocked')
      respond_with_error(:bad_request, blocked_message(twitter_user.screen_name))
      true
    else
      # This is a special case because it call redirect_to and returns false.
      respond_with_error(:bad_request, twitter_exception_handler(e, twitter_user.screen_name))
      false
    end
  end

  def authorized_search?(twitter_user)
    begin
      if twitter_user.persisted?
        twitter_user.load_raw_attrs_text_from_s3!
      end
    rescue S3::Profile::MaybeFetchFailed => e
      logger.warn "#{controller_name}##{action_name} #{__method__} #{e.class} #{twitter_user.inspect}"
      twitter_user.load_raw_attrs_text_from_s3
    end

    if twitter_user.suspended_account? && !can_see_forbidden_or_not_found?(uid: twitter_user.uid)
      respond_with_error(:bad_request, suspended_message(twitter_user.screen_name))
      return false
    end

    return true if twitter_user.public_account?
    return true if user_signed_in? && twitter_user.readable_by?(current_user)

    respond_with_error(:bad_request, protected_message(twitter_user.screen_name))

    false
  rescue => e
    respond_with_error(:bad_request, twitter_exception_handler(e, twitter_user.screen_name))
    false
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

    respond_with_error(:bad_request, too_many_requests_message(rate_limit_reset_in))
    true
  rescue => e
    # This is a special case because it call redirect_to and returns false.
    respond_with_error(:bad_request, twitter_exception_handler(e, twitter_user.screen_name))
    false
  end

  def rate_limit_reset_in
    limit = request_context_client.rate_limit
    [limit.friend_ids, limit.follower_ids, limit.users].select {|l| l[:remaining] == 0}.map {|l| l[:reset_in]}.max
  end

  def has_already_purchased?
    return false if current_user.orders.unexpired.none?

    respond_with_error(:bad_request, t('after_sign_in.has_already_purchased_html', url: settings_path))
    true
  end
end
