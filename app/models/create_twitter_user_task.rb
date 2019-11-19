# Perform a request and log an error
class CreateTwitterUserTask
  attr_reader :request, :twitter_user, :log

  def initialize(request)
    @request = request
  end

  def start!
    @log = CreateTwitterUserLog.create(
        user_id: request.user&.id,
        request_id: request.id,
        uid: request.uid,
    )

    @twitter_user = request.perform!
    request.finished!
    @log.update(status: true)

    self
  rescue => e
    @log.update(error_class: e.class, error_message: e.message)
    raise
  end
end
