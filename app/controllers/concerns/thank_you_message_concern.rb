module ThankYouMessageConcern
  def process_thank_you_message(dm)
    processor = ThankYouMessageProcessor.new(dm.sender_id, dm.text)

    if processor.received?
      processor.send_message
      return true
    end

    false
  end

  class ThankYouMessageProcessor
    include AbstractReportProcessor

    def message_length
      10
    end

    def received_regexp
      /ありがとう|有難う/
    end

    def send_message
      CreateThankYouMessageWorker.perform_async(@uid)
    end
  end
end
