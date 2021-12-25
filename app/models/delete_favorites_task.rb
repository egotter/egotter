class DeleteFavoritesTask
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
  rescue DeleteFavoritesRequest::FavoritesNotFound => e
    SendDeleteFavoritesFinishedMessageWorker.perform_async(request.id)
  rescue DeleteFavoritesRequest::InvalidToken => e
    Airbag.info "#{e.inspect} request=#{request.inspect}"
  rescue DeleteFavoritesRequest::RetryableError => e
    DeleteFavoritesWorker.perform_in(e.retry_in, request.id, @options)
  rescue => e
    request.send_error_message
    raise
  ensure
    if e && e.class != DeleteFavoritesRequest::FavoritesNotFound
      request.update(error_class: e.class, error_message: e.message)
    end
  end

  class AlreadyFinished < StandardError; end
end
