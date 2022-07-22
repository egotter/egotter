class CreateDeleteTweetsUploadCompletedMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in(*args)
    3.seconds
  end

  # options:
  #   :since
  #   :until
  def perform(user_id, options = {})
    user = User.find(user_id)
    user.api_client.verify_credentials

    unless User.egotter_cs.api_client.can_send_dm?(user.uid)
      DeleteTweetsReport.send_upload_completed_starting_message(user)
    end

    send_message(user, options)
  rescue => e
    Airbag.warn "#{e.inspect} user_id=#{user_id} options=#{options.inspect}", backtrace: e.backtrace
  end

  private

  def send_message(user, options)
    error_count ||= 0
    quick_replies = [
        {label: I18n.t('quick_replies.delete_reports.label2'), description: I18n.t('quick_replies.delete_reports.description2')},
        {label: I18n.t('quick_replies.delete_reports.label3'), description: I18n.t('quick_replies.delete_reports.description3')},
        {label: I18n.t('quick_replies.delete_reports.label4'), description: I18n.t('quick_replies.delete_reports.description4')},
    ]

    DeleteTweetsReport.upload_completed_message(user, options.merge('quick_replies' => quick_replies)).deliver!
  rescue => e
    if DirectMessageStatus.cannot_send_messages?(e) && error_count < 4
      error_count += 1
      retry
    else
      SendMessageToSlackWorker.perform_async(:monit_delete_tweets_error, "user_id=#{user.id} class=#{self.class} exception=#{e.inspect}")
      raise
    end
  end
end
