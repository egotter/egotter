require 'active_support/concern'

module AlertMessagesConcern
  extend ActiveSupport::Concern
  include PathsHelper

  included do
  end

  def screen_name_changed_message(screen_name)
    if user_signed_in?
      t('after_sign_in.screen_name_changed_html', user: screen_name, screen_name: screen_name)
    else
      url = sign_in_path(via: current_via('screen_name_changed'))
      t('before_sign_in.screen_name_changed_html', user: screen_name, url: url)
    end
  end

  def signed_in_user_not_authorized_message
    if user_signed_in?
      url = sign_in_path(via: current_via('signed_in_user_not_authorized'))
      t('after_sign_in.signed_in_user_not_authorized_html', user: current_user.screen_name, url: url)
    else
      raise "#{__method__} is called and the user is not signed in"
    end
  end

  def too_many_requests_message(reset_in = 30)
    if user_signed_in?
      reset_in ||= rate_limit_reset_in
      t('after_sign_in.too_many_requests_with_reset_in', seconds: sprintf('%d', reset_in))
    else
      url = sign_in_path(via: current_via('too_many_requests_message'))
      t('before_sign_in.too_many_requests_html', url: url)
    end
  end

  def unknown_alert_message(ex)
    reason = (ex.class.name.demodulize.underscore rescue 'exception')
    logger.info "#{self.class}##{__method__} #{ex.inspect} reason=#{reason}"

    # Show a sign-in button whether current user is signed in or not.
    url = sign_in_path(via: current_via('unknown_alert_message'))
    t('before_sign_in.something_wrong_with_error_html', url: url, error: reason)
  end

  private

  def rate_limit_reset_in
    limit = request_context_client.rate_limit
    [limit.friend_ids, limit.follower_ids, limit.users].select { |l| l[:remaining] == 0 }.map { |l| l[:reset_in] }.max
  end
end
