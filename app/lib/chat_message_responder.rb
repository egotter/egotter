class ChatMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      100
    end

    def received?
      return false if @text.length > message_length
      return false if @text.match?(%r(\Ahttps?://t\.co/\w+\z))

      @chat = true
    end

    def send_message
      if @chat
        CreateChatMessageWorker.perform_async(@uid, text: @text)
      end
    end
  end
end
