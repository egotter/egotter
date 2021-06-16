class CsMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      20
    end

    def received_regexp
      /開始|送信|仲良し/
    end

    def send_message
      CreateCsMessageWorker.perform_async(@uid)
    end
  end
end
