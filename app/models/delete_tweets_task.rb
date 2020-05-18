# Perform a request and log an error
class DeleteTweetsTask
  attr_reader :request, :retry_in, :log

  def initialize(request)
    @request = request
  end

  def start!
    if request.logs.empty?
      send_message_to_slack('Started', request)
    end

    @log = DeleteTweetsLog.create_by(request: request)

    if request.finished?
      @log.update(error_class: DeleteTweetsRequest::AlreadyFinished, error_message: '')
      return
    end

    e = nil
    begin
      request.perform!
    rescue DeleteTweetsRequest::TweetsNotFound => e
      request.finished!
      request.tweet_finished_message if request.tweet
      request.send_finished_message
      send_message_to_slack('Finished', request)

    rescue DeleteTweetsRequest::InvalidToken => e
      Rails.logger.info "#{e.inspect} request=#{request.inspect}"
    rescue DeleteTweetsRequest::RetryableError => e
      @retry_in = e.retry_in
    rescue => e
      request.send_error_message
      raise
    else
      raise "#{self.class}##{__method__} DeleteTweetsRequest#perform! must raise an exception request_id=#{request.id}"
    ensure
      if e
        @log.assign_attributes(error_class: e.class, error_message: e.message)
        @log.retry_in = e.retry_in if (e.respond_to?(:retry_in) && e.retry_in)
        @log.destroy_count = e.destroy_count if (e.respond_to?(:destroy_count) && e.destroy_count)
        @log.save if @log.changed?
      end
    end

    self
  end

  def send_message_to_slack(status, request)
    SlackClient.delete_tweets.send_message("#{status} `#{request.id}` `#{request.user_id}` `#{request.tweet}`")
  rescue => e
    Rails.logger.warn "#{self.class} Sending a message to slack is failed #{e.inspect}"
  end
end
