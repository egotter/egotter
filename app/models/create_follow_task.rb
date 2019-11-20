# Perform a request and log an error
class CreateFollowTask
  attr_reader :request, :log

  def initialize(request)
    @request = request
  end

  def start!
    @log = CreateFollowLog.create_by(request: request)

    request.perform!
    request.finished!

    log.update(status: true)

    self
  rescue => e
    @log.update(error_class: e.class, error_message: e.message)
    raise
  end
end
