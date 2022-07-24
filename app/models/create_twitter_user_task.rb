# Perform a request and log an error
class CreateTwitterUserTask
  attr_reader :request, :twitter_user

  def initialize(request)
    @request = request
  end

  # Create a record or raise an exception
  # context:
  #   :reporting
  def start!(context = nil)
    @request.update(started_at: Time.zone.now)
    @twitter_user = @request.perform!(context)
    @request.update(finished_at: Time.zone.now)
    self
  rescue => e
    @request.update(status_message: e.class) if @request
    raise
  end
end
