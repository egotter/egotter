class MemoMessageResponder < AbstractMessageResponder

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

      if @text.match?(received_regexp)
        @memo = true
      end
    end

    def received_regexp
      %r[\A\s+https://twitter.com/messages/media/\d+\z]
    end

    def send_message
      if @memo
        CreateMemoMessageWorker.perform_async(@uid)
      end
    end
  end
end
