class SearchReportReceivedMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      20
    end

    def received_regexp
      /検索通知(\s|　)*届きました/
    end

    def send_message
      CreateSearchReportReceivedMessageWorker.perform_async(@uid)
    end
  end
end
