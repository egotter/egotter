# Perform a request and log an error
class ResetEgotterTask
  attr_reader :request, :log

  def initialize(request)
    @request = request
  end

  def start!
    @log = ResetEgotterLog.create_by(request: request)

    request.perform!(send_dm: true)
    request.finished!
    @log.finished!

    self
  rescue ResetEgotterRequest::RecordNotFound => e
    request.finished!
    @log.finished!('TwitterUser record not found')
  rescue => e
    @log.failed!(e.class, e.message)
    raise
  end
end
