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
    return unless user.authorized?

    DeleteTweetsReport.send_upload_completed_starting_message(user)

    quick_replies = [
        {label: I18n.t('quick_replies.delete_reports.label2'), description: I18n.t('quick_replies.delete_reports.description2')},
        {label: I18n.t('quick_replies.delete_reports.label3'), description: I18n.t('quick_replies.delete_reports.description3')},
        {label: I18n.t('quick_replies.delete_reports.label4'), description: I18n.t('quick_replies.delete_reports.description4')},
    ]
    DeleteTweetsReport.upload_completed_message(user, options.merge('quick_replies' => quick_replies)).deliver!
  rescue => e
    unless ignorable_report_error?(e)
      Airbag.warn "#{e.inspect} user_id=#{user_id} options=#{options.inspect}"
    end
  end
end
