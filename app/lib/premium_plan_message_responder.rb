class PremiumPlanMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      200
    end

    def received_regexp
      /プラン|お試し|トライアル|有料|有償|購入|返金/
    end

    def send_message
      CreatePremiumPlanMessageWorker.perform_async(@uid)
    end
  end
end
