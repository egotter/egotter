class CloseFriendsMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      20
    end

    def received_regexp
      /仲[良よ]し|ランキング/
    end

    def send_message
      CreateCloseFriendsQuestionedMessageWorker.perform_async(@uid)
    end
  end
end
