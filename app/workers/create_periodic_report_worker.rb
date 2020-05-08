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
    CreatePeriodicReportRequest.find(request_id).update(status: 'skipped')
    logger.warn "The job execution is skipped request_id=#{request_id} options=#{options.inspect}"
  end

  # options:
  #   user_id
  #   create_twitter_user
  def perform(request_id, options = {})
    request = CreatePeriodicReportRequest.find(request_id)

    if !GlobalDirectMessageReceivedFlag.new.exists?(request.user.uid) &&
        GlobalDirectMessageLimitation.new.limited?
      SkippedCreatePeriodicReportWorker.perform_async(request_id, options)
      request.update(status: 'limited')
      return
    end

    request.check_credentials = true

    if self.class == CreateUserRequestedPeriodicReportWorker
      request.check_interval = true
    end

    if options['create_twitter_user']
      request.check_twitter_user
    end

    CreatePeriodicReportTask.new(request).start!

  rescue => e
    notify_airbrake(e, request_id: request_id, options: options)
    logger.warn "#{e.class} #{e.message}"
    logger.info e.backtrace.join("\n")
  end
end
