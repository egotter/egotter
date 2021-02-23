class PeriodicReportReceivedMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      20
    end

    def received_regexp
      /リム(られ)?通知(\s|　)*届きました/
    end

    def send_message
      CreatePeriodicReportReceivedMessageWorker.perform_async(@uid)
    end
  end
end
