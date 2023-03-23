class ChatMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      100
    end

    URL_REGEXP = %r(\Ahttps?://t\.co/\w+\z)
    USERNAME_REGEXP = %r(\A@\w+\z)

    def received?
      return false if @text.length > message_length
      return false if @text.match?(URL_REGEXP)
      return false if @text.match?(USERNAME_REGEXP)

      if @text.match?(THANKS_REGEXP)
        @thanks = true
      else
        @chat = true
      end
    end

    THANKS_REGEXP = Regexp.union(/ありがとう?|有難う|お疲れ様|おつかれさま/, /^(おつかれ|あり|ありごとー|あざす|あざっす|あざます|さんきゅ|てんきゅ|[好す]き|感謝)$/)

    def thanks_regexp
      THANKS_REGEXP
    end

    def send_message
      if @thanks
        CreateThankYouMessageWorker.perform_async(@uid, text: @text)
      elsif @chat
        CreateChatMessageWorker.perform_async(@uid, text: @text)
      end
    end
  end
end
