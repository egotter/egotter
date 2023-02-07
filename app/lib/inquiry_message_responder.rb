class InquiryMessageResponder < AbstractMessageResponder

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
      elsif @text.match?(login_regexp)
        @login = true
      end
    end

    def inquiry_regexp
      /開始|送信|再開|停止|退会|リムられ|ブロック|ミュート|仲良し|ツイ消し/
    end

    def login_regexp
      /ログイン/
    end

    def send_message
      if @inquiry
        CreateInquiryMessageWorker.perform_async(@uid)
      elsif @login
        CreateLoginMessageWorker.perform_async(@uid, from_cs: true)
      end
    end
  end
end
