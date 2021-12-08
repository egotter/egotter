require 'active_support/concern'

module AlertMessagesConcern
  extend ActiveSupport::Concern
  include PathsHelper

  included do
  end

  def unknown_alert_message(ex)
    reason = (ex.class.name.demodulize.underscore rescue 'exception')
    Airbag.info "#{self.class}##{__method__} #{ex.inspect} reason=#{reason}"

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
