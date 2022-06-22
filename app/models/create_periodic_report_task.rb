# Perform a request and log an error
class CreatePeriodicReportTask
  attr_reader :request

  def initialize(request)
    @request = request
  end

  def start!
    return if request.finished?

    request.perform!
    request.finished!
  rescue => e
    request.update(status: e.message.truncate(150)) rescue nil
    raise
  end
end
