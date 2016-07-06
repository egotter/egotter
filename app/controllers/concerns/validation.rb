module Validation
  extend ActiveSupport::Concern

  included do

  end

  def need_login
    redirect_to '/', alert: t('before_sign_in.need_login', sign_in_link: sign_in_link) unless user_signed_in?
  end

  def invalid_screen_name
    if TwitterUser.new(screen_name: search_sn).invalid_screen_name?
      redirect_to '/', alert: t('before_sign_in.invalid_twitter_id')
    end
  end

  def suspended_account
    if @twitter_user.suspended_account?
      redirect_to '/', alert: t('before_sign_in.suspended_user', user: twitter_link(search_sn))
    end
  rescue Twitter::Error::TooManyRequests => e
    redirect_to '/', alert: t('before_sign_in.too_many_requests', sign_in_link: sign_in_link)
  end

  def unauthorized_account
    alert_msg = t('before_sign_in.protected_user',
                  user: twitter_link(@twitter_user.screen_name),
                  sign_in_link: sign_in_link)
    return redirect_to '/', alert: alert_msg if @twitter_user.unauthorized?
  rescue Twitter::Error::TooManyRequests => e
    redirect_to '/', alert: t('before_sign_in.too_many_requests', sign_in_link: sign_in_link)
  end

  def too_many_friends
    # do nothing
    # if @twitter_user.too_many_friends?
    # end
  end

end