# Perform a request and log an error
class DeleteTweetsTask
  def initialize(request, options = {})
    @request = request
    @options = options
  end

  def start!
    if @request.finished?
      @request.update(error_class: AlreadyFinished)
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
  rescue DeleteTweetsRequest::InvalidToken => e
    Rails.logger.info "#{e.inspect} request=#{request.inspect}"
  rescue DeleteTweetsRequest::RetryableError => e
    DeleteTweetsWorker.perform_in(e.retry_in, request.id, @options)
  rescue => e
    request.send_error_message
    raise
  ensure
    if e && e.class != DeleteTweetsRequest::TweetsNotFound
      request.update(error_class: e.class, error_message: e.message)
    end
  end

  class AlreadyFinished < StandardError; end
end
