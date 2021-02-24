class WelcomeReportReceivedMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      20
    end

    def received_regexp
      /初期設定(\s|　)*届きました/
    end

    def send_message
      CreateWelcomeReportReceivedMessageWorker.perform_async(@uid)
    end
  end
end
