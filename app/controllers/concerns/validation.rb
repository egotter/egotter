module Validation
  extend ActiveSupport::Concern

  included do

  end

  def need_login
    redirect_to '/', alert: t('before_sign_in.need_login', sign_in_link: view_context.link_to(t('dictionary.sign_in'), welcome_path)) unless user_signed_in?
  end

  def valid_search_value?
    tu = TwitterUser.new(screen_name: params[:screen_name])

    unless tu.valid_screen_name?
      return redirect_to '/', alert: tu.errors[:screen_name].join(t('dictionary.delim'))
    end

    tu = TwitterUser.build_without_relations(client.user(tu.screen_name), current_user_id, 'search')

    if tu.suspended_account?(twitter_link(tu.screen_name))
      return redirect_to '/', alert: tu.errors[:base].join(t('dictionary.delim'))
    end

    if tu.unauthorized_search?(twitter_link(tu.screen_name), view_context.link_to(t('dictionary.sign_in'), welcome_path))
      return redirect_to '/', alert: tu.errors[:base].join(t('dictionary.delim'))
    end

    @tu = tu
    true
  rescue Twitter::Error::TooManyRequests => e
    redirect_to '/', alert: t('before_sign_in.too_many_requests', sign_in_link: view_context.link_to(t('dictionary.sign_in'), welcome_path))
  rescue Twitter::Error::NotFound => e
    redirect_to '/', alert: t('before_sign_in.not_found')
  rescue Twitter::Error::Unauthorized => e
    alert_msg =
      if user_signed_in?
        t("after_sign_in.unauthorized", sign_out_link: view_context.link_to(t('dictionary.sign_out'), sign_out_path))
      else
        t("before_sign_in.unauthorized", sign_in_link: view_context.link_to(t('dictionary.sign_in'), welcome_path))
      end
    redirect_to '/', alert: alert_msg.html_safe
  rescue Twitter::Error::Forbidden => e
    redirect_to '/', alert: t('before_sign_in.forbidden')
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{params[:screen_name]}"
    redirect_to '/', alert: t('before_sign_in.something_is_wrong', sign_in_link: view_context.link_to(t('dictionary.sign_in'), welcome_path))
  end
end