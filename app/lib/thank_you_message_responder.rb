class ThankYouMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      30
    end

    def received_regexp
      /ありがとう?|有難う|お疲れ様|おつかれさま|(^(おつかれ|あり|ありごとー|あざす|あざっす|あざます|[好す]き|感謝)$)/
    end

    def send_message
      CreateThankYouMessageWorker.perform_async(@uid)
    end
  end
end
