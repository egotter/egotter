class ThankYouMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      30
    end

    RECEIVED_REGEXP = Regexp.union(/ありがとう?|有難う|お疲れ様|おつかれさま/, /^(おつかれ|あり|ありごとー|あざす|あざっす|あざます|てんきゅ|[好す]き|感謝)$/)

    def received_regexp
      RECEIVED_REGEXP
    end

    def send_message
      CreateThankYouMessageWorker.perform_async(@uid)
    end
  end
end
