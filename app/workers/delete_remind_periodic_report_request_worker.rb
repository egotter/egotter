class DeleteRemindPeriodicReportRequestWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'deleting_high', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    10.minutes
  end

  def perform(user_id, options = {})
    RemindPeriodicReportRequest.find_by(user_id: user_id)&.destroy
  rescue => e
    logger.warn "#{e.inspect} user_id=#{user_id}"
  end
end
