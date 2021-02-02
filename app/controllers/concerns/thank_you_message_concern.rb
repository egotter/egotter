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
      20
    end

    def received_regexp
      /ありがとう?|有難う|お疲れ様|おつかれさま|(^(おつかれ|あり|ありごとー|あざす|あざっす|あざます|[好す]き|感謝)$)/
    end

    def send_message
      CreateThankYouMessageWorker.perform_async(@uid)
    end
  end
end
