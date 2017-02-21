module Validation
  extend ActiveSupport::Concern
  include TwitterHelper

  included do

  end

  def need_login
    unless user_signed_in?
      if controller_name == 'relationships'
        redirect_to root_path_for(controller: controller_name), alert: t('before_sign_in.need_login_for_relationships_html', sign_in_path: _sign_in_path)
      else
        redirect_to root_path_for(controller: controller_name), alert: t('before_sign_in.need_login_html', sign_in_path: _sign_in_path)
      end
    end
  end

  def need_admin
    redirect_to root_path unless admin_signed_in?
  end

  def valid_uid?(uid)
    tu = TwitterUser.new(uid: uid)
    if tu.valid_uid?
      true
    else
      if request.xhr?
        render nothing: true, status: 400
      else
        redirect_to root_path, alert: tu.errors[:uid].join(t('dictionary.delim'))
      end
      false
    end
  end

  def existing_uid?(uid)
    return true if TwitterUser.exists?(uid: uid)

    if controller_name == 'searches' && action_name == 'show' && request.device_type != :crawler && !request.xhr?
      @screen_name = @tu.screen_name
      @redirect_path = search_path(screen_name: @screen_name)
      @via = params['via']
      render template: 'searches/create', layout: false
    else
      if request.xhr?
        render nothing: true, status: 400
      else
        redirect_to root_path_for(controller: controller_name), alert: t('before_sign_in.that_page_doesnt_exist')
      end
    end

    false
  end

  def searched_uid?(uid)
    if Util::SearchedUids.new(redis).exists?(uid)
      true
    else
      if request.xhr?
        render nothing: true, status: 400
      else
        redirect_to root_path, alert: t('before_sign_in.that_page_doesnt_exist')
      end
      false
    end
  end

  def valid_screen_name?(screen_name)
    tu = TwitterUser.new(screen_name: screen_name)
    if tu.valid_screen_name?
      true
    else
      redirect_to root_path_for(controller: controller_name), alert: tu.errors[:screen_name].join(t('dictionary.delim'))
      false
    end
  end

  def not_found_screen_name?(screen_name)
    if [Util::NotFoundScreenNames, Util::NotFoundUids].all? { |klass| klass.new(redis).exists?(screen_name) }
      redirect_to root_path_for(controller: controller_name), alert: not_found_message(screen_name)
      true
    else
      false
    end
  end

  def authorized_search?(tu)
    redirect_path = root_path_for(controller: controller_name)

    if tu.suspended_account?
      redirect_to redirect_path, alert: I18n.t('before_sign_in.suspended_user', user: view_context.user_link(tu.screen_name))
      return false
    end

    return true if tu.public_account?
    return true if tu.readable_by?(User.find_by(id: current_user_id))

    redirect_to redirect_path, alert: I18n.t('before_sign_in.protected_user_html', user: view_context.user_link(tu.screen_name), sign_in_path: _sign_in_path)
    false
  rescue Twitter::Error::NotFound => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{current_user_id} #{tu.inspect}"
    redirect_to redirect_path, alert: not_found_message(tu.screen_name)
    false
  rescue Twitter::Error::Forbidden => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{current_user_id} #{tu.inspect}"
    if e.message == 'User has been suspended.'
      CreateForbiddenUserWorker.perform_async(tu.screen_name)
    end
    redirect_to redirect_path, alert: forbidden_message(tu.screen_name)
    false
  rescue Twitter::Error::Unauthorized => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{current_user_id} #{tu.inspect}"
    redirect_to redirect_path, alert: unauthorized_message(tu.screen_name)
    false
  rescue Twitter::Error::TooManyRequests => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{current_user_id} #{tu.inspect}"
    logger.info e.backtrace.take(10).join("\n")
    redirect_to redirect_path, alert: alert_message(e)
    false
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{current_user_id} #{tu.inspect}"
    logger.info e.backtrace.take(10).join("\n")
    redirect_to redirect_path, alert: alert_message(e)
    false
  end

  def not_found_message(screen_name)
    t('before_sign_in.not_found', user: view_context.user_link(screen_name))
  end

  def forbidden_message(screen_name)
    t('before_sign_in.forbidden', user: view_context.user_link(screen_name))
  end

  def unauthorized_message(screen_name)
    t('after_sign_in.unauthorized_html', sign_in_path: _sign_in_path, sign_out_path: sign_out_path)
  end

  def alert_message(ex)
    case
      when ex.kind_of?(Twitter::Error::TooManyRequests)
        t('before_sign_in.too_many_requests_html', sign_in_path: _sign_in_path)
      else
        logger.warn "#{__method__}: unexpected exception #{ex.class} #{ex.message}"
        t('before_sign_in.something_wrong_html', sign_in_path: _sign_in_path)
    end.html_safe
  end

  private

  def _sign_in_path
    welcome_path(via: "#{controller_name}/#{action_name}/validation_error")
  end
end
