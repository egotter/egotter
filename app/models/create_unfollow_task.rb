# Perform a request and log an error
class CreateUnfollowTask
  attr_reader :request, :log

  def initialize(request)
    @request = request
  end

  def start!
    @log = CreateUnfollowLog.create_by(request: request)

    if request.finished?
      log.update(status: false, error_class: UnfollowRequest::AlreadyFinished)
    else
      request.perform!
      request.finished!
      log.update(status: true)
    end

    self
  rescue => e
    @log.update(error_class: e.class, error_message: e.message)
    raise
  end
end
