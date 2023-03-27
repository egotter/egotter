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
      # If this message is from a banned user, don't check the length of text
      if (user = User.find_by(uid: @uid)) && user.banned?
        return (@banned = true)
      end

      return false if @text.length > message_length

      if spam_received?(@text)
        @spam = true
      end
    end

    REGEXP1 = /死ね|殺す|黙れ|馬鹿|役立たず|無能|調子[乗の]んな|やくたたず|きいてんのか|いいかげんに|うるせーよ|うるせ[えぇ]|うっせ[えぇ]|気持ち悪い|キモい|きもい|きしょい|うるせえよ|うるさい|セックス(したい|しよ)|オナニー|クリトリス|オーガズム|オナホール|セフレ/
    REGEXP2 = /^(しね|くず|うざ|くそ|ころす|きえろ|ばか|だまれ|かえれ|こら|きも|ごみ|ゴミ|カス|バカ|ちんぽ|ちんこ|まんこ|うんち|うんこ)$/

    # When this method is called directly, the length of text is not checked
    def spam_received?(text)
      text.match?(REGEXP1) || text.match?(REGEXP2)
    end

    def received_regexp1
      REGEXP1
    end

    def received_regexp2
      REGEXP2
    end

    def send_message
      if @spam
        if (user = User.find_by(uid: @uid))
          CreateViolationEventWorker.perform_async(user.id, 'Spam message', text: @text)
        end
        CreateWarningReportSpamDetectedMessageWorker.perform_async(@uid)
      elsif @banned
        CreateWarningReportSpamDetectedMessageWorker.perform_async(@uid)
      end
    end
  end
end
