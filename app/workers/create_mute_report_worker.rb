class CreateMuteReportWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  include ReportRetryHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in(*args)
    1.hour
  end

  # options:
  def perform(user_id, options = {})
    if StopServiceFlag.on?
      Airbag.info 'StopServiceFlag: CreateMuteReportWorker is stopped', user_id: user_id
      return
    end

    user = User.find(user_id)
    return unless user.authorized?
    return if already_stop_requested?(user)
    return if user.banned?

    if PeriodicReport.send_report_limited?(user.uid)
      retry_current_report(user_id, options)
      return
    end

    unless user.has_valid_subscription?
      unless user.following_egotter?
        CreateMuteReportNotFollowingMessageWorker.perform_async(user.id)
        return
      end

      if PeriodicReport.access_interval_too_long?(user)
        CreateMuteReportAccessIntervalTooLongMessageWorker.perform_async(user.id)
        return
      end

      if requested_by_user? && MuteReport.request_interval_too_short?(user) &&
          !SearchLog.where(user_id: user.id).where('created_at > ?', 1.minute.ago).exists?
        CreateMuteReportRequestIntervalTooShortMessageWorker.perform_async(user.id)
        return
      end
    end

    MuteReport.you_are_muted(user.id, requested_by: requested_by_user? ? 'user' : nil).deliver!
  rescue => e
    if DirectMessageStatus.enhance_your_calm?(e)
      retry_current_report(user_id, options)
    elsif ignorable_report_error?(e)
      # Do nothing
    else
      Airbag.exception e, user_id: user_id, options: options
    end
  end

  private

  def already_stop_requested?(user)
    StopMuteReportRequest.exists?(user_id: user.id) && self.class != CreateMuteReportByUserRequestWorker
  end

  def requested_by_user?
    self.class == CreateMuteReportByUserRequestWorker
  end
end
