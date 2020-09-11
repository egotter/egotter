# Perform a request and log an error
class DeleteTweetsTask
  attr_reader :request, :retry_in, :log

  def initialize(request)
    @request = request
  end

  def start!
    if request.logs.empty?
      SendDeleteTweetsNotFinishedWorker.perform_in(30.minutes, request.id, user_id: request.user_id)
    end

    @log = DeleteTweetsLog.create_by(request: request)

    if request.finished?
      @log.update(error_class: AlreadyFinished)
      return
    end

    perform_request!
  end

  def perform_request!
    e = nil
    request.perform!
  rescue DeleteTweetsRequest::TweetsNotFound => e
    request.finished!
    request.tweet_finished_message if request.tweet
    request.send_finished_message

  rescue DeleteTweetsRequest::InvalidToken => e
    # Do nothing
  rescue DeleteTweetsRequest::RetryableError => e
    @retry_in = e.retry_in
  rescue => e
    request.send_error_message
    raise
  else
    raise "#{self.class}##{__method__} DeleteTweetsRequest#perform! must raise an exception request_id=#{request.id}"
  ensure
    update_log_with_error(e) if e
  end

  def update_log_with_error(e)
    if @log
      @log.assign_attributes(error_class: e.class, error_message: e.message)
      @log.retry_in = e.retry_in if e.respond_to?(:retry_in) && e.retry_in
      @log.destroy_count = e.destroy_count if e.respond_to?(:destroy_count) && e.destroy_count
      @log.save if @log.changed?
    end
  end

  class AlreadyFinished < StandardError; end
end
