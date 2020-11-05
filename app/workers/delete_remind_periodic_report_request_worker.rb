class DeleteRemindPeriodicReportRequestWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'deleting_high', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    if (uid = options['uid'] || options[:uid])
      uid
    else
      user_id
    end
  end

  def unique_in
    10.minutes
  end

  # options:
  #   uid
  def perform(user_id, options = {})
    if (uid = options['uid'] || options[:uid])
      user_id = User.find_by(uid: uid).id
    end

    RemindPeriodicReportRequest.find_by(user_id: user_id)&.destroy
  rescue => e
    logger.warn "#{e.inspect} user_id=#{user_id} options=#{options.inspect}"
  end
end
