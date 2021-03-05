class PeriodicReportReceivedWebAccessMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      20
    end

    REGEXP = /アクセス通知(\s|　)*届きました|(URLに)?アクセスしました/

    def received_regexp
      REGEXP
    end

    def send_message
      CreatePeriodicReportReceivedWebAccessMessageWorker.perform_async(@uid)
    end
  end
end
