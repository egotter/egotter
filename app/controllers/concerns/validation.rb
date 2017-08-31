require 'active_support/concern'

module Concerns::Validation
  extend ActiveSupport::Concern
  include Concerns::ExceptionHandler

  included do

  end

  def need_login
    unless user_signed_in?
      if controller_name == 'relationships'
        redirect_to root_path_for(controller: controller_name), alert: t('before_sign_in.need_login_for_relationships_html', url: kick_out_error_path('need_login'))
      else
        redirect_to root_path_for(controller: controller_name), alert: t('before_sign_in.need_login_html', url: kick_out_error_path('need_login'))
      end
    end
  end

  def require_admin!
    redirect_to root_path unless admin_signed_in?
  end

  def valid_uid?(uid)
    twitte_user = TwitterUser.new(uid: uid)
    return true if twitte_user.valid_uid?

    if request.xhr?
      head :bad_request
    else
      redirect_to root_path, alert: twitte_user.errors[:uid].join(t('dictionary.delim'))
    end

    false
  end

  def twitter_user_persisted?(uid)
    return true if TwitterUser.exists?(uid: uid)

    if request.xhr?
      head :bad_request
      return false
    end

    if request.from_crawler? || from_minor_crawler?(request.user_agent)
      redirect_to root_path_for(controller: controller_name), alert: t('before_sign_in.that_page_doesnt_exist')
      return false
    end

    if (controller_name == 'searches' && action_name == 'show') || (controller_name == 'timelines' && action_name == 'show')
      @screen_name = @tu.screen_name
      @redirect_path = timeline_path(screen_name: @screen_name)
      @via = params['via']
      render template: 'searches/create', layout: false
    else
      redirect_to root_path_for(controller: controller_name), alert: t('before_sign_in.that_page_doesnt_exist')
    end

    false
  end

  def twitter_db_user_persisted?(uid)
    return true if TwitterDB::User.exists?(uid: uid)

    logger.warn "#{controller_name}##{action_name}: TwitterDB::User not found. #{uid}"
    TwitterDB::User::Batch.fetch_and_import([uid], client: client)
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
      redirect_to root_path, alert: t('before_sign_in.that_page_doesnt_exist')
    end

    false
  end

  def valid_screen_name?(screen_name = nil)
    screen_name ||= params[:screen_name]
    twitter_user = TwitterUser.new(screen_name: screen_name)
    if twitter_user.valid_screen_name?
      true
    else
      redirect_to root_path_for(controller: controller_name), alert: twitter_user.errors[:screen_name].join(t('dictionary.delim'))
      false
    end
  end

  def forbidden_screen_name?(screen_name = nil)
    screen_name ||= params[:screen_name]
    if ForbiddenUser.exists?(screen_name: screen_name)
      redirect_to root_path_for(controller: controller_name), alert: forbidden_message(screen_name)
      true
    else
      false
    end
  end

  def not_found_screen_name?(screen_name = nil)
    screen_name ||= params[:screen_name]
    if NotFoundUser.exists?(screen_name: screen_name)
      redirect_to root_path_for(controller: controller_name), alert: not_found_message(screen_name)
      true
    else
      false
    end
  end

  def authorized_search?(twitter_user)
    redirect_path = root_path_for(controller: controller_name)

    if twitter_user.suspended_account?
      redirect_to redirect_path, alert: I18n.t('before_sign_in.suspended_user', user: view_context.user_link(twitter_user.screen_name))
      return false
    end

    return true if twitter_user.public_account?
    return true if twitter_user.readable_by?(User.find_by(id: current_user_id))

    if request.xhr?
      head :bad_request
    else
      redirect_to redirect_path, alert: I18n.t('before_sign_in.protected_user_html', user: view_context.user_link(twitter_user.screen_name), url: kick_out_error_path('protected'))
    end

    false
  rescue => e
    twitter_exception_handler(e, twitter_user.screen_name)
    false
  end

  def too_many_searches?
    return false if request.from_crawler? || from_minor_crawler?(request.user_agent) || user_signed_in?

    limit = Rails.configuration.x.constants['too_many_searches']
    if today_search_histories_size >= limit
      redirect_to root_path, alert: t('before_sign_in.too_many_searches_html', limit: limit, url: kick_out_error_path('too_many_searches'))
      true
    end

    false
  end
end
