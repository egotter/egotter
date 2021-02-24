class PeriodicReportReceivedWebAccessMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      20
    end

    def received_regexp
      /アクセス通知(\s|　)*届きました|URLにアクセスしました/
    end

    def send_message
      CreatePeriodicReportReceivedWebAccessMessageWorker.perform_async(@uid)
    end
  end
end
