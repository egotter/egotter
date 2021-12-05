require 'active_support/concern'

module ReportErrorHandler
  extend ActiveSupport::Concern

  def ignorable_report_error?(e)
    disposable_report? ||
        TwitterApiStatus.unauthorized?(e) ||
        TwitterApiStatus.invalid_or_expired_token?(e) ||
        DirectMessageStatus.your_account_suspended?(e) ||
        DirectMessageStatus.protect_out_users_from_spam?(e) ||
        DirectMessageStatus.might_be_automated?(e) ||
        DirectMessageStatus.you_have_blocked?(e) ||
        DirectMessageStatus.not_allowed_to_access_or_delete?(e) ||
        DirectMessageStatus.cannot_send_messages?(e) ||
        DirectMessageStatus.cannot_find_specified_user?(e) ||
        DirectMessageStatus.not_following_you?(e)
  end

  # TODO Remove later
  def disposable_report?
    false
  end
end
