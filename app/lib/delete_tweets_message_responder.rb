class DeleteTweetsMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      20
    end

    def received_regexp
      /削除|消去|全消し|ツイ消し|クリーナ/
    end

    def send_message
      CreateDeleteTweetsQuestionedMessageWorker.perform_async(@uid)
    end
  end
end
