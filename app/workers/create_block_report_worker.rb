# Implement DispatchBlockReportWorker
class CreateBlockReportWorker
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
    return if already_stop_requested?(user)

    if PeriodicReport.send_report_limited?(user.uid)
      logger.info "Send block report later user_id=#{user_id} raised=false"
      CreateBlockReportWorker.perform_in(1.hour + rand(30).minutes, user_id, options.merge(delay: true))
      return
    end

    unless user.has_valid_subscription?
      unless user.following_egotter?
        CreateBlockReportNotFollowingMessageWorker.perform_async(user.id)
        return
      end

      if PeriodicReport.access_interval_too_long?(user)
        CreateBlockReportAccessIntervalTooLongMessageWorker.perform_async(user.id)
        return
      end

      if requested_by_user? && BlockReport.request_interval_too_short?(user)
        CreateBlockReportRequestIntervalTooShortMessageWorker.perform_async(user.id)
        return
      end
    end

    BlockReport.you_are_blocked(user.id, requested_by: requested_by_user? ? 'user' : nil).deliver!
  rescue => e
    if DirectMessageStatus.enhance_your_calm?(e)
      logger.warn "Send block report later user_id=#{user_id} raised=true"
      CreateBlockReportWorker.perform_in(1.hour + rand(30).minutes, user_id, options.merge(delay: true))
    elsif ignorable_report_error?(e)
      # Do nothing
    else
      logger.warn "#{e.inspect} user_id=#{user_id} options=#{options.inspect}"
    end
  end

  private

  def already_stop_requested?(user)
    StopBlockReportRequest.exists?(user_id: user.id) && self.class != CreateBlockReportByUserRequestWorker
  end

  def requested_by_user?
    self.class == CreateBlockReportByUserRequestWorker
  end
end
