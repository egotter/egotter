class ThankYouMessageResponder
  def initialize(uid, text)
    @processor = Processor.new(uid, text)
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

  class << self
    def from_dm(dm)
      new(dm.sender_id, dm.text)
    end
  end

  class Processor
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
