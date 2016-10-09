module Validation
  extend ActiveSupport::Concern

  included do

  end

  def need_login
    redirect_to root_path, alert: t('before_sign_in.need_login', sign_in_link: sign_in_link) unless user_signed_in?
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
    if TwitterUser.exists?(uid: uid)
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
      redirect_to root_path, alert: tu.errors[:screen_name].join(t('dictionary.delim'))
      false
    end
  end

  def authorized_search?(tu)
    if tu.suspended_account?
      redirect_to root_path, alert: I18n.t('before_sign_in.suspended_user', user: user_link(tu))
      return false
    end

    if tu.readable_by?(User.find_by(id: current_user_id))
      return true
    end

    redirect_to root_path, alert: I18n.t('before_sign_in.protected_user', user: user_link(tu), sign_in_link: sign_in_link)
    false
  rescue Twitter::Error::TooManyRequests => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{tu.inspect}"
    redirect_to root_path, alert: t('before_sign_in.too_many_requests', sign_in_link: sign_in_link)
    false
  rescue Twitter::Error::NotFound => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{tu.inspect}"
    redirect_to root_path, alert: t('before_sign_in.not_found')
    false
  rescue Twitter::Error::Unauthorized => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{tu.inspect}"
    alert_msg =
      if user_signed_in?
        t("after_sign_in.unauthorized", sign_out_link: view_context.link_to(t('dictionary.sign_out'), sign_out_path))
      else
        t("before_sign_in.unauthorized", sign_in_link: sign_in_link)
      end
    redirect_to root_path, alert: alert_msg.html_safe
    false
  rescue Twitter::Error::Forbidden => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{tu.inspect}"
    redirect_to root_path, alert: t('before_sign_in.forbidden')
    false
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{tu.inspect}"
    logger.warn e.backtrace.slice(0, 10).join("\n")
    redirect_to root_path, alert: t('before_sign_in.something_is_wrong', sign_in_link: sign_in_link)
    false
  end

  private

  def user_link(tu)
    view_context.link_to(tu.mention_name, "https://twitter.com/#{tu.screen_name}", target: '_blank')
  end

  def sign_in_link
    view_context.link_to(t('dictionary.sign_in'), welcome_path)
  end
end