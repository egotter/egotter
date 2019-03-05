class DeleteTweetsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(request_id, options = {})
    request_id
  end

  def after_skip(*args)
    logger.warn "Skipped #{args.inspect}"
  end

  def retry_in
    60.seconds
  end

  def perform(request_id, options = {})
    request = DeleteTweetsRequest.find(request_id)
    user = request.user
    log = DeleteTweetsLog.create!(user_id: user.id, request_id: request_id, message: 'Starting')

    unless user.authorized?
      log.update(message: "[#{user.screen_name}] is not authorized.")
      return
    end

    if user.api_client.user[:statuses_count] == 0
      log.update(status: true, message: "[#{user.screen_name}] hasn't tweeted.")
      request.finished!
      return
    end

    do_perform(request, log, options)

  rescue => e
    error_message = e.message.truncate(100)
    logger.warn "#{e.class} #{error_message} #{request_id} #{options.inspect}"
    log.update(error_class: e.class, error_message: error_message)
  end

  def do_perform(request, log, options)
    request.perform!
    destroy_count = request.destroy_count

    if request.timeout?
      log.update(error_class: Timeout::Error, error_message: "Timeout and destroyed #{destroy_count}")
      retry_after(request.id, retry_in, options)
      return
    end

    if request.too_many_requests?
      log.update(error_class: Twitter::Error::TooManyRequests, error_message: "TooManyRequests and destroyed #{destroy_count}")
      retry_after(request.id, request.error.rate_limit.reset_in.to_i, options)
      return
    end

    if request.tweets_not_found?
      log.update(status: true, message: "Tweets not found")
      request.finished!
      request.send_finished_message
      return
    end

    log.update(message: "Destroyed #{destroy_count}")
    retry_after(request.id, retry_in, options)
  end

  def retry_after(request_id, retry_in, options)
    reset_queue(request_id)
    DeleteTweetsWorker.perform_in(retry_in, request_id, options.merge(skip_unique: true))
  end

  def reset_queue(request_id)
    QueueingRequests.new(self.class).delete(request_id)
    RunningQueue.new(self.class).delete(request_id)
  end
end
