class PremiumPlanMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      20
    end

    def received_regexp
      /お試し|有料|購入|返金/
    end

    def send_message
      CreatePremiumPlanMessageWorker.perform_async(@uid)
    end
  end
end
