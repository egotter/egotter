module PrettyIconMessageConcern
  def process_pretty_icon_message(dm)
    processor = PrettyIconMessageProcessor.new(dm.sender_id, dm.text)

    if processor.received?
      processor.send_message
      return true
    end

    false
  end

  class PrettyIconMessageProcessor
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
