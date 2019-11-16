class DeleteTweetsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'deleting_high', retry: 0, backtrace: false

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
    log = DeleteTweetsLog.create!(user_id: user.id, request_id: request_id, message: I18n.t('activerecord.attributes.delete_tweets_request.processing'))


    unless user.authorized?
      redirect_path = Rails.application.routes.url_helpers.delete_tweets_path
      url = Rails.application.routes.url_helpers.sign_in_url(via: "delete_tweets_worker/not_authorized", redirect_path: redirect_path)
      log.update(message: I18n.t('activerecord.attributes.delete_tweets_request.not_authorized_html', name: user.screen_name, url: url))
      request.finished!
      return
    end

    begin
      user.api_client.verify_credentials
    rescue => e
      redirect_path = Rails.application.routes.url_helpers.delete_tweets_path
      url = Rails.application.routes.url_helpers.sign_in_url(via: "delete_tweets_worker/invalid_token", redirect_path: redirect_path)
      log.update(message: I18n.t('activerecord.attributes.delete_tweets_request.invalid_token_html', name: user.screen_name, url: url))
      request.finished!
      return
    end

    if user.api_client.user[:statuses_count] == 0
      log.update(status: true, message: I18n.t('activerecord.attributes.delete_tweets_request.zero_tweets'))
      request.finished!
      return
    end

    do_perform(request, log, options)

  rescue => e
    error_message = e.message.truncate(100)
    logger.warn "#{e.class} #{error_message} #{request_id} #{options.inspect}"
    logger.info e.backtrace.join("\n")

    log.update(message: I18n.t('activerecord.attributes.delete_tweets_request.something_error'))
    log.update(error_class: e.class, error_message: error_message)
    request.finished!
    request.send_error_message
  end

  def do_perform(request, log, options)
    request.perform!
    destroy_count = request.destroy_count

    if request.timeout?
      log.update(message: I18n.t('activerecord.attributes.delete_tweets_request.timeout', count: destroy_count, retry_in: retry_in))
      retry_after(request.id, retry_in, options)
      return
    end

    if request.too_many_requests?
      reset_in = request.error.rate_limit.reset_in.to_i
      log.update(message: I18n.t('activerecord.attributes.delete_tweets_request.too_many_requests', count: destroy_count, reset_in: reset_in))
      log.update(error_class: Twitter::Error::TooManyRequests, error_message: reset_in)
      retry_after(request.id, reset_in, options)
      return
    end

    if request.tweets_not_found?
      request.finished!
      log.finished!(I18n.t('activerecord.attributes.delete_tweets_request.zero_tweets'))
      request.send_finished_message
      return
    end

    log.update(message: I18n.t('activerecord.attributes.delete_tweets_request.continue', count: destroy_count))
    retry_after(request.id, 1.second, options)
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
