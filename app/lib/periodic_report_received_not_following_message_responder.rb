class PeriodicReportReceivedNotFollowingMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      20
    end

    def received_regexp
      /フォロー通知(\s|　)*届きました/
    end

    def send_message
      CreatePeriodicReportReceivedNotFollowingMessageWorker.perform_async(@uid)
    end
  end
end
