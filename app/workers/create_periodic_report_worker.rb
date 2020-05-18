class CreatePeriodicReportWorker
  include Sidekiq::Worker
  include Concerns::AirbrakeErrorHandler
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    CreatePeriodicReportRequest.find(request_id).user_id
  end

  UNIQUE_IN = 5.seconds

  def unique_in
    UNIQUE_IN
  end

  def after_skip(request_id, options = {})
    request = CreatePeriodicReportRequest.find(request_id)
    request.update(status: 'job_skipped')

    if user_requested_job?
      waiting_time = CreatePeriodicReportMessageWorker::UNIQUE_IN + 3.seconds
      CreatePeriodicReportMessageWorker.perform_in(waiting_time, request.user_id, request_interval_too_short: true)
    end

    logger.info "The job execution is skipped request_id=#{request_id} options=#{options.inspect}"
  end

  def user_requested_job?
    self.class == CreateUserRequestedPeriodicReportWorker
  end

  def batch_requested_job?
    self.class == CreatePeriodicReportWorker
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
    request.check_following_status = user_requested_job?
    request.check_allotted_messages_count = batch_requested_job?

    options['create_twitter_user'] = true unless options.has_key?('create_twitter_user')
    request.check_twitter_user = options['create_twitter_user']

    CreatePeriodicReportTask.new(request).start!

  rescue => e
    notify_airbrake(e, request_id: request_id, options: options)
    logger.warn "#{e.class} #{e.message}"
    logger.info e.backtrace.join("\n")
  end
end
