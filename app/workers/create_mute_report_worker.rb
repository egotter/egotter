class CreateMuteReportWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in(*args)
    1.hour
  end

  # options:
  def perform(user_id, options = {})
    user = User.find(user_id)
    return unless user.authorized?
    return if StopMuteReportRequest.exists?(user_id: user.id)

    if PeriodicReport.send_report_limited?(user.uid)
      logger.info "Send mute report later user_id=#{user_id} raised=false"
      CreateMuteReportWorker.perform_in(1.hour + rand(30).minutes, user_id, options.merge(delay: true))
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
    end

    MuteReport.you_are_muted(user.id).deliver!
  rescue => e
    if DirectMessageStatus.enhance_your_calm?(e)
      logger.warn "Send mute report later user_id=#{user_id} raised=true"
      CreateMuteReportWorker.perform_in(1.hour + rand(30).minutes, user_id, options.merge(delay: true))
    elsif ignorable_report_error?(e)
      # Do nothing
    else
      logger.warn "#{e.inspect} user_id=#{user_id} options=#{options.inspect}"
    end
  end
end
