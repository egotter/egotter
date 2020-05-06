class CreatePeriodicReportWorker
  include Sidekiq::Worker
  include Concerns::AirbrakeErrorHandler
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  def unique_in
    1.minute
  end

  # options:
  #   user_id
  #   create_twitter_user
  def perform(request_id, options = {})
    request = CreatePeriodicReportRequest.find(request_id)

    if !GlobalDirectMessageReceivedFlag.new.exists?(request.user.uid) &&
        GlobalDirectMessageLimitation.new.limited?
      SkippedCreatePeriodicReportWorker.perform_async(request_id, options)
      return
    end

    if options['create_twitter_user']
      create_request = CreateTwitterUserRequest.create(
          requested_by: self.class,
          user_id: request.user_id,
          uid: request.user.uid)
      task = CreateTwitterUserTask.new(create_request)
      begin
        task.start!
      rescue => e
        logger.info "#{e.inspect} request_id=#{request_id} create_request_id=#{create_request.id}"
      end
    end

    CreatePeriodicReportTask.new(request).start!

  rescue => e
    notify_airbrake(e, request_id: request_id, options: options)
    logger.warn "#{e.class} #{e.message}"
    logger.info e.backtrace.join("\n")
  end
end
