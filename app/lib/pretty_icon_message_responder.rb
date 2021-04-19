class PrettyIconMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      20
    end

    def received_regexp
      /アイコン|可愛い|かわいい|カワイイ/
    end

    def send_message
      CreatePrettyIconMessageWorker.perform_async(@uid)
    end
  end
end
