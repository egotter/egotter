module Validation
  extend ActiveSupport::Concern

  included do

  end

  def need_login
    redirect_to '/', alert: t('before_sign_in.need_login', sign_in_link: welcome_link) unless user_signed_in?
  end

  def valid_search_value?
    tu = TwitterUser.new(screen_name: params[:screen_name])

    unless tu.valid_screen_name?
      return redirect_to '/', alert: tu.errors[:screen_name]
    end

    tu = TwitterUser.build_without_relations(client.user(tu.screen_name), current_user_id, 'search')

    if tu.suspended_account?(twitter_link(tu.screen_name))
      return redirect_to '/', alert: tu.errors[:base]
    end

    if tu.unauthorized_search?(twitter_link(tu.screen_name), welcome_link)
      return redirect_to '/', alert: tu.errors[:base]
    end

    ValidUidList.new(redis).add(tu.uid, current_user_id)
    ValidTwitterUserSet.new(redis).set(
      tu.uid,
      current_user_id,
      {
        uid: tu.uid,
        screen_name: tu.screen_name,
        user_id: current_user_id,
        user_info: tu.user_info,
        egotter_context: tu.egotter_context
      }
    )
    @tu = tu
  rescue Twitter::Error::TooManyRequests => e
    redirect_to '/', alert: t('before_sign_in.too_many_requests', sign_in_link: welcome_link)
  rescue Twitter::Error::NotFound => e
    redirect_to '/', alert: t('before_sign_in.not_found')
  rescue Twitter::Error::Unauthorized => e
    alert_msg =
      if user_signed_in?
        t("after_sign_in.unauthorized", sign_out_link: sign_out_link)
      else
        t("before_sign_in.unauthorized", sign_in_link: welcome_link)
      end
    redirect_to '/', alert: alert_msg.html_safe
  rescue Twitter::Error::Forbidden => e
    redirect_to '/', alert: t('before_sign_in.forbidden')
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{params[:screen_name]}"
    redirect_to '/', alert: t('before_sign_in.something_is_wrong', sign_in_link: welcome_link)
  end
end