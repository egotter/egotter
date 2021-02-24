class WelcomeReportStartingMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      20
    end

    def received_regexp
      /初期設定(\s|　)*(開始|送信)/
    end

    def send_message
      CreateWelcomeReportStartingMessageWorker.perform_async(@uid)
    end
  end
end
