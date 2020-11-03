class CreatePeriodicReportWorker
  include Sidekiq::Worker
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
      CreatePeriodicReportRequestIntervalTooShortMessageWorker.perform_in(waiting_time, request.user_id)
    end

    logger.info "The job of #{self.class} is skipped request_id=#{request_id} options=#{options.inspect}"
  end

  def _timeout_in(*args)
    60.seconds
  end

  def timeout?
    @start && Time.zone.now - @start > _timeout_in
  end

  def after_timeout(request_id, options = {})
    logger.warn "The job of #{self.class} timed out request_id=#{request_id} options=#{options.inspect}"
    CreatePeriodicReportRequest.find(request_id).append_status('timeout').save
  end

  # options:
  #   user_id
  #   create_twitter_user
  #   scheduled_request
  #   send_only_if_changed
  def perform(request_id, options = {})
    @start = Time.zone.now
    request = CreatePeriodicReportRequest.find(request_id)

    if sending_dm_limited?(request.user.uid)
      SkippedCreatePeriodicReportWorker.perform_async(request_id, options)
      request.update(status: 'limited')
      return
    end

    request.worker_context = self.class
    request.check_credentials = true

    if request.user.has_valid_subscription?
      request.check_interval = false
      request.check_following_status = false
      request.check_allotted_messages_count = false
      request.check_web_access = false
    else
      request.check_interval = user_requested_job? && !options.has_key?('scheduled_request')
      request.check_following_status = !request.user.has_valid_subscription? && user_requested_job?
      request.check_allotted_messages_count = batch_requested_job?
      request.check_web_access = !request.user.has_valid_subscription? && user_requested_job?
    end

    request.send_only_if_changed = options['send_only_if_changed']

    options['create_twitter_user'] = true unless options.has_key?('create_twitter_user')
    request.check_twitter_user = options['create_twitter_user']

    CreatePeriodicReportTask.new(request).start!

    if timeout?
      after_timeout(request_id, options)
    end

  rescue => e
    logger.warn "#{e.inspect} request_id=#{request_id} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end

  private

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
end
