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
      /(([?？]|ですか)$)|プラン|お試し|トライアル|有料|有償|購入|返金/
    end

    def send_message
      CreateQuestionMessageWorker.perform_async(@uid)
    end
  end
end
