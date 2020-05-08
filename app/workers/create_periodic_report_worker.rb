class CreatePeriodicReportWorker
  include Sidekiq::Worker
  include Concerns::AirbrakeErrorHandler
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    CreatePeriodicReportRequest.find(request_id).user_id
  end

  def unique_in
    1.minute
  end

  def after_skip(request_id, options = {})
    request = CreatePeriodicReportRequest.find(request_id)
    request.update(status: 'skipped')

    if user_requested_job?
      CreatePeriodicReportMessageWorker.perform_in(1.minute, request.user_id, interval_too_short: true)
    end

    logger.warn "The job execution is skipped request_id=#{request_id} options=#{options.inspect}"
  end

  def user_requested_job?
    self.class == CreateUserRequestedPeriodicReportWorker
  end

  def sending_dm_limited?(uid)
    !GlobalDirectMessageReceivedFlag.new.exists?(uid) &&
        GlobalDirectMessageLimitation.new.limited?
  end

  # options:
  #   user_id
  #   create_twitter_user
  def perform(request_id, options = {})
    request = CreatePeriodicReportRequest.find(request_id)

    if sending_dm_limited?(request.user.uid)
      SkippedCreatePeriodicReportWorker.perform_async(request_id, options)
      request.update(status: 'limited')
      return
    end

    request.worker_context = self.class
    request.check_credentials = true
    request.check_interval = user_requested_job?

    options['create_twitter_user'] = true unless options.has_key?('create_twitter_user')
    request.check_twitter_user = options['create_twitter_user']

    CreatePeriodicReportTask.new(request).start!

  rescue => e
    notify_airbrake(e, request_id: request_id, options: options)
    logger.warn "#{e.class} #{e.message}"
    logger.info e.backtrace.join("\n")
  end
end
