module SpamMessageConcern
  def process_spam_message(dm)
    processor = SpamMessageProcessor.new(dm.sender_id, dm.text)

    if processor.received?
      processor.send_message
      return true
    end

    false
  end

  class SpamMessageProcessor
    include AbstractReportProcessor

    def message_length
      6
    end

    def received_regexp
      /死ね|殺す|役立たず|無能|やくたたず|きいてんのか|いいかげんに|うっせえ|気持ち悪い|キモい|きもい|うるせえよ|うるさい|(^(しね|くず|くそ|ころす|こら|おい|ごみ|ゴミ|ちんぽ|ちんこ|うんち|うんこ)$)/
    end

    def send_message
      CreateWarningReportSpamDetectedMessageWorker.perform_async(@uid)
    end
  end
end
