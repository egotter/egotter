class QuestionMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      100
    end

    def received?
      return false if @text.length > message_length

      if @text.match?(inquiry_regexp)
        @inquiry = true
      elsif @text.match?(question_regexp)
        @question = true
      end
    end

    def inquiry_regexp
      /(^#{PeriodicReport::QUICK_REPLY_INQUIRY[:label]}$)|プラン|お試し|トライアル|有料|有償|購入|返金/
    end

    def question_regexp
      /([?？]|ですか)$/
    end

    def send_message
      if @inquiry
        CreateQuestionMessageWorker.perform_async(@uid, text: @text, inquiry: true)
      elsif @question
        CreateQuestionMessageWorker.perform_async(@uid, text: @text, question: true)
      end
    end
  end
end
