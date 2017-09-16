require 'active_support/concern'

module Concerns::Validation
  extend ActiveSupport::Concern
  include Concerns::ExceptionHandler
  include CrawlersHelper
  include PathsHelper
  include SearchHistoriesHelper

  included do

  end

  def need_login
    unless user_signed_in?
      redirect_to root_path_for(controller: controller_name), alert: t('before_sign_in.need_login_html', url: kick_out_error_path('need_login'))
    end
  end

  def require_admin!
    redirect_to root_path unless admin_signed_in?
  end

  def valid_uid?(uid = nil)
    uid ||= params[:uid]
    twitter_user = TwitterUser.new(uid: uid)
    return true if twitter_user.valid_uid?

    if request.xhr?
      head :bad_request
    else
      redirect_to root_path, alert: twitter_user.errors.full_messages.join(t('dictionary.delim'))
    end

    false
  end

  def twitter_user_persisted?(uid)
    return true if TwitterUser.exists?(uid: uid)

    if request.xhr?
      head :bad_request
      return false
    end

    if from_crawler?
      redirect_to root_path_for(controller: controller_name), alert: t('application.not_found')
      return false
    end

    if controller_name == 'timelines' && action_name == 'show'
      @screen_name = @tu.screen_name
      @redirect_path = timeline_path(screen_name: @screen_name)
      @via = params['via']
      render template: 'searches/create', layout: false
    else
      redirect_to root_path_for(controller: controller_name), alert: t('application.not_found')
    end

    false
  end

  def twitter_db_user_persisted?(uid)
    return true if TwitterDB::User.exists?(uid: uid)

    logger.warn "#{controller_name}##{action_name}: TwitterDB::User not found. #{uid}"
    TwitterDB::User::Batch.fetch_and_create(uid, client: client)
    true
  rescue => e
    logger.warn "#{controller_name}##{action_name}: TwitterDB::User not found. #{e.class} #{e.message} #{uid}"
    false
  end

  def searched_uid?(uid)
    return true if Util::SearchRequests.exists?(uid)

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
      redirect_to root_path_for(controller: controller_name), alert: twitter_user.errors.full_messages.join(t('dictionary.delim'))
      false
    end
  end

  def can_see_forbidden_or_not_found?(condition)
    user_signed_in? && TwitterUser.exists?(condition)
  end

  def forbidden_screen_name?(screen_name = nil)
    screen_name ||= params[:screen_name]
    if ForbiddenUser.exists?(screen_name: screen_name) && !can_see_forbidden_or_not_found?(screen_name: screen_name)
      redirect_to root_path_for(controller: controller_name), alert: forbidden_message(screen_name)
      true
    else
      false
    end
  end

  def not_found_screen_name?(screen_name = nil)
    screen_name ||= params[:screen_name]
    if NotFoundUser.exists?(screen_name: screen_name) && !can_see_forbidden_or_not_found?(screen_name: screen_name)
      redirect_to root_path_for(controller: controller_name), alert: not_found_message(screen_name)
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
      redirect_to root_path_for(controller: controller_name), alert: blocked_message(twitter_user.screen_name)
      true
    else
      twitter_exception_handler(e, twitter_user.screen_name)
      false
    end
  end

  def authorized_search?(twitter_user)
    redirect_path = root_path_for(controller: controller_name)

    if twitter_user.suspended_account? && !can_see_forbidden_or_not_found?(uid: twitter_user.uid)
      redirect_to redirect_path, alert: suspended_message(twitter_user.screen_name)
      return false
    end

    return true if twitter_user.public_account?
    return true if user_signed_in? && twitter_user.readable_by?(current_user)

    if request.xhr?
      head :bad_request
    else
      redirect_to redirect_path, alert: protected_message(twitter_user.screen_name)
    end

    false
  rescue => e
    twitter_exception_handler(e, twitter_user.screen_name)
    false
  end

  def too_many_searches?
    return false if from_crawler? || search_histories_remaining > 0

    if user_signed_in?
      redirect_to root_path, alert: t('after_sign_in.too_many_searches_html', limit: search_histories_limit)
    else
      redirect_to root_path, alert: t('before_sign_in.too_many_searches_html', limit: search_histories_limit, url: kick_out_error_path('too_many_searches'))
    end

    true
  end
end
