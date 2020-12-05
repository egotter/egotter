# Perform a request and log an error
class ResetEgotterTask
  attr_reader :request

  def initialize(request)
    @request = request
  end

  def start!
    request.perform!(send_dm: true)
    request.finished!
    SendResetEgotterFinishedWorker.perform_async(request.id)

    self
  rescue ResetEgotterRequest::TwitterUserNotFound => e
    request.finished!
  rescue => e
    raise
  end
end
