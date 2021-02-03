class PrettyIconMessageResponder
  def initialize(dm)
    @processor = Processor.new(dm.sender_id, dm.text)
  end

  def respond
    if @processor.received?
      @processor.send_message
      return true
    end

    false
  rescue => e
    Rails.logger.warn e.inspect
    false
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      20
    end

    def received_regexp
      /アイコン.*(可愛|かわい)/
    end

    def send_message
      CreatePrettyIconMessageWorker.perform_async(@uid)
    end
  end
end
