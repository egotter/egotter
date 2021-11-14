class TweetCleanerMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      30
    end

    def received_regexp
      /DM|送信|テスト|てすと/
    end

    def send_message
      CreateTweetCleanerMessageWorker.perform_async(@uid)
    end
  end
end
