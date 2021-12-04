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
    @twitter_user = @request.perform!(context)
    @request.finished!
    self
  rescue => e
    @request.update(status_message: e.class) if @request
    raise
  end
end
