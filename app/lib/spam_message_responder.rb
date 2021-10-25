class SpamMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      10
    end

    def received?
      return false if @text.length > message_length

      if @text.match?(received_regexp1) || @text.match?(received_regexp2)
        @spam = true
      end
    end

    def received_regexp1
      /死ね|殺す|黙れ|馬鹿|役立たず|無能|やくたたず|きいてんのか|いいかげんに|うるせーよ|うるせ[えぇ]|うっせえ|気持ち悪い|キモい|きもい|きしょい|うるせえよ|うるさい/
    end

    def received_regexp2
      /^(しね|くず|うざ|くそ|ころす|きえろ|ばか|だまれ|かえれ|こら|きも|ごみ|ゴミ|バカ|ちんぽ|ちんこ|まんこ|うんち|うんこ)$/
    end

    def send_message
      if @spam
        if (user = User.find_by(uid: @uid))
          CreateViolationEventWorker.perform_async(user.id, 'Spam message', text: @text)
        end
        CreateWarningReportSpamDetectedMessageWorker.perform_async(@uid)
      end
    end
  end
end
