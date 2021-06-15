module SpamMessageConcern
  def process_spam_message(dm)
    processor = SpamMessageProcessor.new(dm.sender_id, dm.text)

    if processor.received?
      if (user = User.find_by(uid: dm.sender_id))
        CreateViolationEventWorker.perform_async(user.id, 'Spam message')
      end
      processor.send_message
      return true
    end

    false
  end

  class SpamMessageProcessor
    include AbstractReportProcessor

    def message_length
      10
    end

    REGEXP = /死ね|殺す|黙れ|馬鹿|役立たず|無能|やくたたず|きいてんのか|いいかげんに|うるせーよ|うるせ[えぇ]|うっせえ|気持ち悪い|キモい|きもい|きしょい|うるせえよ|うるさい|(^(しね|くず|うざ|くそ|ころす|きえろ|ばか|だまれ|かえれ|こら|おい|きも|ごみ|ゴミ|バカ|ちんぽ|ちんこ|まんこ|うんち|うんこ)$)/

    def received_regexp
      REGEXP
    end

    def send_message
      CreateWarningReportSpamDetectedMessageWorker.perform_async(@uid)
    end
  end
end
