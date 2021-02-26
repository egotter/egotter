class QuestionMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      100
    end

    def received_regexp
      /([?？]|ですか)$/
    end

    def send_message
      CreateQuestionMessageWorker.perform_async(@uid)
    end
  end
end
