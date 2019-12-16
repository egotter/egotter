# Perform a request and log an error
class ResetEgotterTask
  attr_reader :request, :log

  def initialize(request)
    @request = request
  end

  def start!
    if request.logs.empty?
      send_message_to_slack('Started', request)
    end

    @log = ResetEgotterLog.create_by(request: request)

    request.perform!(send_dm: true)
    request.finished!
    @log.finished!
    send_message_to_slack('Finished', request)

    self
  rescue ResetEgotterRequest::RecordNotFound => e
    request.finished!
    @log.finished!('TwitterUser record not found')
  rescue => e
    @log.failed!(e.class, e.message)
    raise
  end

  def send_message_to_slack(status, request)
    SlackClient.reset_egotter.send_message("`#{status}` `#{request.id}` `#{request.user_id}`")
  rescue => e
    logger.warn "Sending a message to slack is failed #{e.inspect}"
  end
end
