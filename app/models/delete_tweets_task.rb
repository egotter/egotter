# Perform a request and log an error
class DeleteTweetsTask
  def initialize(request, options = {})
    @request = request
    @options = options
  end

  def start!
    if @request.finished?
      @request.update(error_message: 'This request is already finished.')
      return
    end

    perform_request!(@request)
  end

  private

  def perform_request!(request)
    e = nil
    request.perform!
  rescue DeleteTweetsRequest::TweetsNotFound => e
    request.finished!
    SendDeleteTweetsFinishedWorker.perform_async(request.id)
  rescue DeleteTweetsRequest::InvalidToken => e
    # Do nothing
  rescue DeleteTweetsRequest::TemporarilyLocked => e
    # Do nothing
  rescue DeleteTweetsRequest::RetryableError => e
    DeleteTweetsWorker.perform_in(e.retry_in, request.id, @options)
  rescue => e
    request.send_error_message
    raise
  ensure
    if e && e.class != DeleteTweetsRequest::TweetsNotFound
      request.update(error_message: e.inspect)
    end
  end
end
