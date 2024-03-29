class AiInquiryMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      20
    end

    def received_regexp
      /開始|送信|再開|停止|退会|リムられ|ブロック|ミュート|仲良し|ツイ消し/
    end

    def send_message
      CreateInquiryMessageWorker.perform_async(@uid, from_uid: User::EGOTTER_AI_UID)
    end
  end
end
