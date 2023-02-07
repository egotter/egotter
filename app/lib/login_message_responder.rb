class LoginMessageResponder < AbstractMessageResponder

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

      if @text.match?(login_regexp)
        @login = true
      end
    end

    def login_regexp
      /ログイン/
    end

    def send_message
      if @login
        CreateLoginMessageWorker.perform_async(@uid)
      end
    end
  end
end
